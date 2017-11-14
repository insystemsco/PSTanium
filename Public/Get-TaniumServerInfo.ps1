function Get-TaniumServerInfo {
    [CmdletBinding()]
    Param (
        # The Tanium Server FQDN or IP
        [Parameter(Mandatory = $false,Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server = $script:PSTanium.Server,
        # Credentials for Tanium Server
        [Parameter(Mandatory = $false,Position = 1)]
        [ValidateNotNull()]
        [PSCredential]
        $Credential = $script:PSTanium.Credential
    )
    Process {
        $uri = [Uri]"https://$($Server):443/info.json"
        $iwrParams = @{
            Uri         = $uri
            Method      = "Get"
            ErrorAction = "Stop"
        }
        if (!$IsCoreCLR) {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        else {
            $iwrParams["SkipCertificateCheck"] = $true
        }
        $headers = @{
            Accept            = "*/*"
            "Accept-Encoding" = "gzip, deflate"
        }
        try {
            $session = Get-TaniumSession -Server $Server -Credential $Credential
            $headers["session"] = $session
            $result = Invoke-WebRequest -Headers $headers @iwrParams
            return $result.Content | ConvertFrom-Json
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}