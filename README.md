# AutoBuild-Actions

Actions for Building OpenWRT

Supported Devices: `d-team_newifi-d2`

使用方法/Usage:
----

1. 首先需要获取[Github Token](https://github.com/settings/tokens/new),`Note`项随意填写,`Select scopes`项如果不懂就全部打勾,勾选完成后点击`Generate token`.

2. 复制获取到的Token值,一定要保存到本地,Token值只会显示一次!

3. `Fork`此仓库,然后进入到你的`AutoBuild-Actions`仓库

4. 点击右上方菜单中的`Settings`,点击`Secrets`-`New Secrets`,`Name`项填写`RELEASE_TOKEN`,`Value`项填写你在第 1 步中获取到的token
