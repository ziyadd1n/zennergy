$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$files = @('index.html','styles.css','script.js')
$assets = @{}
foreach ($file in $files) {
  $path = Join-Path $root $file
  if (!(Test-Path -LiteralPath $path)) { throw "Missing required file: $file" }
  $content = [IO.File]::ReadAllText($path)
  if ([string]::IsNullOrWhiteSpace($content)) { throw "Empty file: $file" }
  $assets['/' + $file] = $content
}
$html = $assets['/index.html']
$ids = @([regex]::Matches($html, 'id="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
if (@($ids | Select-Object -Unique).Count -ne $ids.Count) { throw 'Duplicate HTML IDs' }
foreach ($match in [regex]::Matches($html, 'href="#([^"]+)"')) {
  if ($match.Groups[1].Value -notin $ids) { throw "Missing anchor target: $($match.Groups[1].Value)" }
}
foreach ($required in @('Ziyaddin Omarov','ziyaddinomerov@gmail.com','+8618519400559','linkedin.com/in/ziyaddin-omarov','id="insights"','id="careers"')) {
  if (!$html.Contains($required)) { throw "Missing expected content: $required" }
}
$assetJson = ConvertTo-Json -InputObject $assets -Compress
$portraitPath = Join-Path $root 'assets/ziyaddin-omarov.png'
if (!(Test-Path -LiteralPath $portraitPath)) { throw 'Missing founder portrait' }
$portraitBytes = [IO.File]::ReadAllBytes($portraitPath)
if ($portraitBytes.Length -lt 8 -or [BitConverter]::ToString($portraitBytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') { throw 'Invalid PNG portrait' }
if (!$html.Contains('src="assets/ziyaddin-omarov.png"')) { throw 'Founder portrait is not referenced by the page' }
$portraitJson = ConvertTo-Json -InputObject ([Convert]::ToBase64String($portraitBytes)) -Compress
$worker = 'const assets = ' + $assetJson + '; const portrait = ' + $portraitJson + ';' + @'

const types = {"/index.html":"text/html; charset=utf-8","/styles.css":"text/css; charset=utf-8","/script.js":"text/javascript; charset=utf-8"};
export default {
  async fetch(request) {
    if (request.method !== "GET" && request.method !== "HEAD") return new Response("Method not allowed", {status:405,headers:{Allow:"GET, HEAD"}});
    const path = new URL(request.url).pathname;
    if (path === "/assets/ziyaddin-omarov.png") {
      return new Response(request.method === "HEAD" ? null : Uint8Array.from(atob(portrait), c => c.charCodeAt(0)), {headers:{"Content-Type":"image/png","X-Content-Type-Options":"nosniff","Cache-Control":"public, max-age=3600"}});
    }
    const key = path === "/" ? "/index.html" : path;
    if (!Object.prototype.hasOwnProperty.call(assets,key)) return new Response("Not found",{status:404});
    return new Response(request.method === "HEAD" ? null : assets[key], {headers:{"Content-Type":types[key],"X-Content-Type-Options":"nosniff","Referrer-Policy":"strict-origin-when-cross-origin","Cache-Control":"public, max-age=300"}});
  }
};
'@
New-Item -ItemType Directory -Force (Join-Path $root 'dist/server') | Out-Null
[IO.File]::WriteAllText((Join-Path $root 'dist/server/index.js'), $worker, [Text.UTF8Encoding]::new($false))
Write-Output 'Build passed: required files, unique IDs, anchor targets and founder details checked. Worker output created.'
