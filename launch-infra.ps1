$ErrorActionPreference = "Continue"
$Region = "eu-west-3"
$Infra  = "C:\Users\miro\Downloads\infra-summer-intership"
$ZoneId = "Z03120723IDL4EDT628C2"

function Step($t)  { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Check($t) { if ($LASTEXITCODE -ne 0) { throw "ECHEC : $t" } }

Set-Location $Infra

Step "Saisie de la nouvelle cle Groq (masquee)"
$sec  = Read-Host "Nouvelle cle Groq (gsk_...)" -AsSecureString
$groq = [System.Net.NetworkCredential]::new("", $sec).Password
if (-not $groq.StartsWith("gsk_") -or $groq.Length -lt 30) { throw "Cle Groq invalide" }

Step "Attente des images ECR (frontend + backend), 20 min max"
$tag = $null
for ($i = 0; $i -lt 60 -and -not $tag; $i++) {
    $b = aws ecr describe-images --repository-name voicecraft-prod-backend --region $Region --query "sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]" --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $b -and $b -ne "None") {
        $b = $b.Trim()
        $f = aws ecr describe-images --repository-name voicecraft-prod-frontend --region $Region --image-ids imageTag=$b --query "imageDetails[0].imageTags[0]" --output text 2>$null
        if ($LASTEXITCODE -eq 0 -and $f -and $f.Trim() -eq $b) { $tag = $b }
    }
    if (-not $tag) { Write-Host "  pas encore d'images, nouvelle verification dans 20 s..."; Start-Sleep -Seconds 20 }
}
if (-not $tag) { throw "Aucune image dans ECR : relance le pipeline summer-intership (job tag-and-push)." }
Write-Host "Tag d'image : $tag" -ForegroundColor Green
$env:TF_VAR_image_tag = $tag

Step "terraform init"
terraform init -input=false
Check "terraform init"

Step "Zone Route53"
$st = terraform state list
if (-not ($st -match "module\.dns\.aws_route53_zone")) {
    Write-Host "Import de la zone $ZoneId"
    terraform import -input=false "module.dns.aws_route53_zone.this" $ZoneId
    Check "import de la zone (verifie le nom de la ressource dans modules\dns\main.tf)"
}

Step "Certificat ACM (etape 1/2)"
terraform apply -input=false -auto-approve -target="module.acm.aws_acm_certificate.this"
Check "apply du certificat ACM"

Step "Plan complet (etape 2/2)"
terraform plan -input=false -out=tfplan
Check "terraform plan"

Step "Apply complet (15 a 25 min, ne pas interrompre)"
terraform apply -input=false tfplan
Check "terraform apply"

Step "Trust policy GitHub OIDC"
if (Test-Path "$Infra\trust.json") {
    aws iam update-assume-role-policy --role-name voicecraft-prod-github-deploy --policy-document file://trust.json --region $Region
    Check "update-assume-role-policy"
}

Step "Cle Groq dans SSM"
[IO.File]::WriteAllText("$Infra\groq.tmp", $groq, (New-Object System.Text.UTF8Encoding $false))
aws ssm put-parameter --name /voicecraft/prod/groq_api_key --type SecureString --value file://groq.tmp --overwrite --region $Region | Out-Null
$rc = $LASTEXITCODE
Remove-Item "$Infra\groq.tmp" -Force
Remove-Variable groq, sec
if ($rc -ne 0) { throw "ECHEC : put-parameter Groq" }

aws ecs update-service --cluster voicecraft-prod-app --service backend --force-new-deployment --region $Region | Out-Null
Check "redeploiement backend"

Step "Attente de la stabilisation des services ECS"
aws ecs wait services-stable --cluster voicecraft-prod-app --services frontend backend --region $Region
Check "services ECS stables"

Step "Verification"
aws ecs describe-services --cluster voicecraft-prod-app --services frontend backend --region $Region --query "services[].[serviceName,runningCount,desiredCount]" --output table
curl.exe -s -o NUL -w "app.voicecraft-plateform.website -> HTTP %{http_code}`n" https://app.voicecraft-plateform.website
curl.exe -s https://app.voicecraft-plateform.website/api/health
Write-Host ""
Write-Host "Infra recreee." -ForegroundColor Green