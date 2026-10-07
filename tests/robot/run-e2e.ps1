<#
.SYNOPSIS
  รัน Robot Framework E2E ทีเดียว — activate venv · ตั้ง env · รัน · เปิด report

.EXAMPLE
  .\run-e2e.ps1                      # รันทั้งหมด (headless)
  .\run-e2e.ps1 -Tag ui              # เฉพาะ UI (ต้องมี FE :5173)
  .\run-e2e.ps1 -Tag api             # เฉพาะ API (ต้องมี BE :3001)
  .\run-e2e.ps1 -Tag ui -Headed      # ดู browser ทำงานจริง
  .\run-e2e.ps1 -Headed -SlowMo 500  # ดูแบบช้า ๆ (หน่วงทุก action 500 ms)
  .\run-e2e.ps1 -Suite borrow-form   # เฉพาะ suite ไฟล์ borrow-form.robot
  .\run-e2e.ps1 -DryRun              # เช็ค syntax อย่างเดียว
  .\run-e2e.ps1 -Tag smoke -NoOpen   # ไม่เปิด report อัตโนมัติ
#>
[CmdletBinding()]
param(
  [string]$Tag,
  [string]$Test,
  [string]$Suite,
  [int]$SlowMo = 0,
  [switch]$Headed,
  [switch]$DryRun,
  [switch]$NoOpen,
  [string]$BaseUrl = 'http://localhost:5173',
  [string]$ApiUrl = 'http://localhost:3001',
  [ValidateSet('TRACE', 'DEBUG', 'INFO', 'WARN')]
  [string]$LogLevel = 'INFO'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$robot = Join-Path $root '.venv\Scripts\robot.exe'

if (-not (Test-Path $robot)) {
  Write-Host 'ไม่พบ .venv — สร้างและติดตั้งก่อน' -ForegroundColor Yellow
  python -m venv (Join-Path $root '.venv')
  & (Join-Path $root '.venv\Scripts\python.exe') -m pip install -r (Join-Path $root 'requirements.txt')
  & (Join-Path $root '.venv\Scripts\rfbrowser.exe') init chromium
}

# Robot อ่าน PYTHONIOENCODING ตรง ๆ — รูปแบบ "utf-8:surrogateescape" ทำให้พัง
$env:PYTHONIOENCODING = 'utf-8'
$env:E2E_BASE_URL = $BaseUrl
$env:E2E_API_URL = $ApiUrl
$env:E2E_HEADLESS = if ($Headed) { 'false' } else { 'true' }
$env:E2E_SLOWMO = "$($SlowMo)ms"

$args = @('-d', (Join-Path $root 'results'), '--loglevel', $LogLevel)
if ($Tag) { $args += @('-i', $Tag) }
if ($Test) { $args += @('-t', $Test) }
if ($Suite) { $args += @('-s', $Suite) }
if ($DryRun) { $args += '--dryrun' }
$args += (Join-Path $root 'suites')

Write-Host "robot $($args -join ' ')" -ForegroundColor Cyan
& $robot @args
$code = $LASTEXITCODE

if (-not $NoOpen -and -not $DryRun) {
  $report = Join-Path $root 'results\report.html'
  if (Test-Path $report) { Start-Process $report }
}
exit $code
