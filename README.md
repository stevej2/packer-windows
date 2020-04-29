# Windows Templates for Packer

### Introduction

This repository contains a Windows template that can be used to create boxes for
Vagrant using Packer ([Website](https://www.packer.io))
([Github](https://github.com/mitchellh/packer)).


### Windows Editions

You can modify the Windows version by editing the Autounattend.xml file, changing the
`ImageInstall`>`OSImage`>`InstallFrom`>`MetaData`>`Value` element (e.g. to
Windows Server 2012 R2 SERVERDATACENTER).

To retrieve the correct ImageName from an ISO file use the following two commands.

```
PS C:\> Mount-DiskImage -ImagePath C:\iso\Windows_InsiderPreview_Server_2_16237.iso
PS C:\> Get-WindowsImage -ImagePath e:\sources\install.wim

ImageIndex       : 1
ImageName        : Windows Server 2016 SERVERSTANDARDACORE
ImageDescription : Windows Server 2016 SERVERSTANDARDACORE
ImageSize        : 7,341,507,794 bytes

ImageIndex       : 2
ImageName        : Windows Server 2016 SERVERDATACENTERACORE
ImageDescription : Windows Server 2016 SERVERDATACENTERACORE
ImageSize        : 7,373,846,520 bytes
```

### Product Keys

The `Autounattend.xml` files are configured to work correctly with trial ISOs
(which will be downloaded and cached for you the first time you perform a
`packer build`). If you would like to use retail or volume license ISOs, you
need to update the `UserData`>`ProductKey` element as follows:

* Uncomment the `<Key>...</Key>` element
* Insert your product key into the `Key` element

If you are going to configure your VM as a KMS client, you can use the product
keys at http://technet.microsoft.com/en-us/library/jj612867.aspx. These are the
default values used in the `Key` element.

### Using existing ISOs

If you have already downloaded the ISOs or would like to override them, set
these additional variables:

* iso_url - path to existing ISO
* iso_checksum - md5sum of existing ISO (if different)

```
packer build -var 'iso_url=./server2016.iso' .\windows_2016.json
```

### Windows Updates

The scripts in this repo will NOT install all Windows updates – by default – during
Windows Setup. This is a _very_ time consuming process, depending on the age of
the OS and the quantity of updates released since the last service pack. See `WITH WINDOWS UPDATES` and
 `WITHOUT WINDOWS UPDATES` sections in `Autounattend.xml`:

```xml
<!-- WITHOUT WINDOWS UPDATES -->
<!-- END WITHOUT WINDOWS UPDATES -->
<!-- WITH WINDOWS UPDATES -->
<!--
<SynchronousCommand wcm:action="add">
    <CommandLine>cmd.exe /c a:\microsoft-updates.bat</CommandLine>
    <Order>98</Order>
    <Description>Enable Microsoft Updates</Description>
</SynchronousCommand>
<SynchronousCommand wcm:action="add">
    <CommandLine>cmd.exe /c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File a:\win-updates.ps1</CommandLine>
    <Description>Install Windows Updates</Description>
    <Order>100</Order>
    <RequiresUserInput>true</RequiresUserInput>
</SynchronousCommand>
-->
<!-- END WITH WINDOWS UPDATES -->
```

### WinRM

These boxes use WinRM by default.

### Hyper-V Support

If you are running Windows 10, Windows Server 2016 or later, then you can also use these packerfiles to build
a Hyper-V virtual machine. e.g.:

```
packer build --only hyperv-iso -var 'hyperv_switchname=Ethernet' -var 'iso_url=./server2016.iso' .\windows_2016_docker.json
```

Where `Ethernet` is the name of my default Hyper-V Virtual Switch. You then can use this box with Vagrant to spin up a Hyper-V VM.

#### Generation 2 VMs possibly not required

Some of these images use Hyper-V "Generation 2" VMs to enable the latest features and faster booting. However, an extra manual step is needed to put the needed files into ISOs because Gen2 VMs don't support virtual floppy disks.

* `windows_server_insider.json`
* `windows_server_insider_docker.json`
* `windows_10_insider.json`

Before running `packer build`, be sure to run `./make_unattend_iso.ps1` first. Otherwise the build will fail on a missing ISO file

```none
hyperv-iso output will be in this color.

1 error(s) occurred:

* Secondary Dvd image does not exist: CreateFile ./iso/windows_server_insider_unattend.iso: The system cannot find the file specified.
```

### KVM/qemu support

If you are using Linux and have KVM/qemu configured, you can use these packerfiles to build a KVM virtual machine.
To build a KVM/qemu box, first make sure:

* You are a member of the kvm group on your machine. You can list the groups you are member of by running `groups`. It should
  include the `kvm` group. If you're not a member, run `sudo usermod -aG kvm $(whoami)` to add yourself.
* You have downloaded [the iso image with the Windows drivers for paravirtualized KVM/qemu hardware](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso).
  You can do this from the command line: `wget -nv -nc https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -O virtio-win.iso`.

You can use the following sample command to build a KVM/qemu box:

```
packer build --only=qemu --var virtio_win_iso=./virtio-win.iso ./windows_2019_docker.json
```


### Using .box Files With Vagrant

The generated box files include a Vagrantfile template that is suitable for use
with Vagrant 1.7.4+, but the latest version is always recommended.

Example Steps for Hyper-V:

```
vagrant box add windows_2016_docker windows_2016_docker_hyperv.box
vagrant init windows_2016_docker
vagrant up --provider hyperv
```
