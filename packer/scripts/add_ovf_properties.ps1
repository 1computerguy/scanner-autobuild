Param(
    [Parameter(Position=1)]
    [string]$PHOTON_VERSION,

    [Parameter(Position=2)]
    [string]$PHOTON_APPLIANCE_NAME,

    [Parameter(Position=3)]
    [string]$FINAL_PHOTON_APPLIANCE_NAME,

    [Parameter(Position=4)]
    [string]$PHOTON_OVF_TEMPLATE,

    [Parameter(Position=5)]
    [string]$OUTPUT_PATH
)

$ovf_template = "$OUTPUT_PATH\$PHOTON_APPLIANCE_NAME"
$photon_template = "$FINAL_PHOTON_APPLIANCE_NAME.xml"
$output_file = "$ovf_template.ovf"

Remove-Item -Force "$ovf_template.mf" -Confirm:$false

(Get-Content $PHOTON_OVF_TEMPLATE).replace('{{VERSION}}', $PHOTON_VERSION) | Set-Content $photon_template

(Get-Content $output_file).replace('<VirtualHardwareSection>', '<VirtualHardwareSection ovf:transport="com.vmware.guestInfo">') | Set-Content $output_file
(Get-Content $output_file).replace("    </VirtualHardwareSection>", (Get-Content $photon_template | % { "$_`n" })) | Set-Content $output_file
Set-Content $output_file -Value (Get-Content $output_file | Select-String -Pattern '^      <vmw:ExtraConfig ovf:required="false" vmw:key="nvram".*$' -NotMatch)
Set-Content $output_file -Value (Get-Content $output_file | Select-String -Pattern '^    <File ovf:href=\"$PHOTON_APPLIANCE_NAME-file1.nvram\".*$' -NotMatch)

ovftool.exe $output_file "$FINAL_PHOTON_APPLIANCE_NAME.ova"
Remove-Item -Recurse -Force "$OUTPUT_PATH" -Confirm:$false
Remove-Item -Force $photon_template -Confirm:$false
