Param(
    [Parameter(Position=1)]
    [string]$PHOTON_VERSION,

    [Parameter(Position=2)]
    [string]$PHOTON_APPLIANCE_NAME,

    [Parameter(Position=3)]
    [string]$FINAL_PHOTON_APPLIANCE_NAME,

    [Parameter(Position=4)]
    [string]$PHOTON_OVF_TEMPLATE
)

$output_path = "..\output-vmware-esxi"
$photon_template = "photon.xml"
$ovf_template = $OUTPUT_PATH/$PHOTON_APPLIANCE_NAME/$PHOTON_APPLIANCE_NAME

Remove-Item -Force $ovf_template.mf -Confirm:$true 

(Get-Content $PHOTON_OVF_TEMPLATE).replace('{{VERSION}}', $PHOTON_VERSION) | Set-Content $photon_template

(Get-Content $output_file).replace('<VirtualHardwareSection>', '<VirtualHardwareSection ovf:transport="com.vmware.guestInfo">') | Set-Content $ovf_template.ovf
(Get-Content $output_file).replace('</vmw:BootOrderSection>', ' r photon.xml') | Set-Content $ovf_template.ovf
Set-Content $output_file -Value (Get-Content $output_file | Select-String -Pattern '^      <vmw:ExtraConfig ovf:required="false" vmw:key="nvram".*$' -NotMatch)
Set-Content $output_file -Value (Get-Content $output_file | Select-String -Pattern '^    <File ovf:href=\"$PHOTON_APPLIANCE_NAME-file1.nvram\".*$' -NotMatch)

ovftool.exe $ovf_template.ovf $OUTPUT_PATH/$FINAL_PHOTON_APPLIANCE_NAME.ova
Remove-Item -Recurse -Force $OUTPUT_PATH\$PHOTON_APPLIANCE_NAME -Confirm:$false
Remove-Item -Force $photon_template -Confirm:$false
