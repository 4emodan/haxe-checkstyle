# Checkstyle for Haxe

[![Haxelib Version](https://img.shields.io/github/tag/adireddy/haxe-checkstyle.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/checkstyle) [![Built with Grunt](https://cdn.gruntjs.com/builtwith.png)](http://gruntjs.com/) [![Build Status](https://travis-ci.org/adireddy/haxe-checkstyle.svg?branch=master)](https://travis-ci.org/adireddy/haxe-checkstyle)

![logo](https://raw.githubusercontent.com/adireddy/haxe-checkstyle/master/logo.png)

Automated code analysis tool ideal for projects that want to enforce coding conventions.

Code conventions improve readability, allowing team members to understand each others code better.

Please note that this project was derived from [haxelint](https://github.com/mcheshkov/haxelint) created by [@mcheshkov](https://github.com/mcheshkov).

###Installation

```haxe
haxelib install checkstyle
```

###Configuration

More information in [wiki page](https://github.com/adireddy/haxe-checkstyle/wiki/Haxe-Checkstyle).

```json
{
	"checks": [
		{
			"type": "Anonymous",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "ArrayInstantiation",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "BlockFormat",
			"props": {
				"severity": "ERROR",
				"emptyBlockCheck": false
			}
		},
		{
			"type": "ConstantName",
			"props": {
				"severity": "ERROR",
				"format": "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$",
				"tokens": [
					"INLINE"
				]
			}
		},
		{
			"type": "ConstantName",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "CyclomaticComplexity",
			"props": {
				"thresholds": [
					{
						"severity": "WARNING",
						"complexity": 20
					},
					{
						"severity": "ERROR",
						"complexity": 30
					}
				]
			}
		},
		{
			"type": "Dynamic",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "EmptyLines",
			"props": {
				"severity": "INFO",
				"maxConsecutiveEmptyLines": 1
			}
		},
		{
			"type": "ERegInstantiation",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "FileLength",
			"props": {
				"severity": "WARNING",
				"max": 2000
			}
		},
		{
			"type": "HexadecimalLiterals",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "IndentationCharacter",
			"props": {
				"severity": "INFO",
				"character": "tab"
			}
		},
		{
			"type": "LineLength",
			"props": {
				"severity": "ERROR",
				"maxCharacters": 200
			}
		},
		{
			"type": "ListenerName",
			"props": {
				"severity": "ERROR",
				"listeners": [
					"addEventListener",
					"addListener",
					"on",
					"once"
				]
			}
		},
		{
			"type": "LocalVariableName",
			"props": {
				"severity": "ERROR",
				"format": "^[a-z]+[a-zA-Z0-9]*$"
			}
		},
		{
			"type": "MemberName",
			"props": {
				"severity": "ERROR",
				"format": "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$",
				"tokens": [
					"ENUM"
				]
			}
		},
		{
			"type": "MemberName",
			"props": {
				"severity": "ERROR",
				"format": "^[a-z]+[a-zA-Z0-9]*$",
				"tokens": [
					"PUBLIC",
					"PRIVATE",
					"TYPEDEF"
				]
			}
		},
		{
			"type": "MethodLength",
			"props": {
				"severity": "ERROR",
				"maxFunctionLines": 50
			}
		},
		{
			"type": "MethodName",
			"props": {
				"severity": "ERROR",
				"format": "^[a-z]+[a-zA-Z0-9]*$",
				"tokens": []
			}
		},
		{
			"type": "NeedBraces",
			"props": {
				"severity": "WARNING",
				"allowSingleLineStatement": true,
				"tokens": []
			}
		},
		{
			"type": "NestedForDepth",
			"props": {
				"severity": "ERROR",
				"max": 1
			}
		},
		{
			"type": "NestedIfDepth",
			"props": {
				"severity": "ERROR",
				"max": 1
			}
		},
		{
			"type": "NestedTryDepth",
			"props": {
				"severity": "ERROR",
				"max": 1
			}
		},
		{
			"type": "Override",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "ParameterName",
			"props": {
				"severity": "ERROR",
				"format": "^[a-z]+[a-zA-Z0-9]*$"
			}
		},
		{
			"type": "ParameterNumber",
			"props": {
				"severity": "INFO",
				"max": 7,
				"ignoreOverriddenMethods": false
			}
		},
		{
			"type": "PublicPrivate",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "Return",
			"props": {
				"severity": "INFO",
				"allowEmptyReturn": true
			}
		},
		{
			"type": "Spacing",
			"props": {
				"severity": "INFO",
				"spaceIfCondition": true,
				"spaceAroundBinop": true,
				"spaceAroundBinop": true,
				"ignoreRangeOperator": true
			}
		},
		{
			"type": "TabForAligning",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "TODOComment",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "TrailingWhitespace",
			"props": {
				"severity": "INFO"
			}
		},
		{
			"type": "Type",
			"props": {
				"severity": "ERROR"
			}
		},
		{
			"type": "TypeName",
			"props": {
				"severity": "ERROR",
				"format": "^I[A-Z]+[a-zA-Z0-9]*$",
				"tokens": [
					"INTERFACE"
				]
			}
		},
		{
			"type": "TypeName",
			"props": {
				"severity": "ERROR",
				"format": "^[A-Z]+[a-zA-Z0-9]*$",
				"tokens": [
					"CLASS",
					"ENUM",
					"TYPEDEF"
				]
			}
		},
		{
			"type": "VariableInitialisation",
			"props": {
				"severity": "ERROR"
			}
		}
	]
}
```

###Options

To see all the options available run the following command.

`haxelib run checkstyle`

```
[-p | --path] <loc>              : Set reporter path
[-x | --xslt] <x>                : Set reporter style (XSLT)
[-r | --reporter] <reporterName> : Set reporter
[-c | --config] <configPath>     : Set config file
[--list-checks]                  : List all checks
[--list-reporters]				 : List all reporters 
[-report]                        : Generate build time report
[-s | --source] <sourcePath>     : Set sources to process
```
###Compile Time Report

Now when using default `xml` reporting, you can display readable compile time report in console by passing `-report` option.

`haxelib run checkstyle -s src -p report.xml -report`

###Hudson and Bamboo Integration

You can generate the report in checkstyle XML format that can be integrated with Hudson and Bamboo easily.

You can also set XSLT style for the XML generated. See the sample below.

`haxelib run checkstyle -s src -c config.json -p report.xml -x report.xsl`

Sample Hudson Checkstyle Trend Chart:

![hudson](https://raw.githubusercontent.com/adireddy/haxe-checkstyle/master/hudson.png)

###Reference

http://checkstyle.sourceforge.net

http://haxe.org/manual/class-field-visibility.html

http://adireddy.github.io/haxe/haxe-access-modifiers-return-types

###Issues

Found any bug? Please create a new [issue](https://github.com/adireddy/haxe-checkstyle/issues/new).