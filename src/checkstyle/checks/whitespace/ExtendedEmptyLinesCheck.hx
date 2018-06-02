package checkstyle.checks.whitespace;

import checkstyle.checks.whitespace.ListOfEmptyLines.EmptyLineRange;

@name("ExtendedEmptyLines")
@desc("Checks for consecutive empty lines.")
class ExtendedEmptyLinesCheck extends Check {

	public var max:Int;
	public var skipSingleLineTypes:Bool;

	public var defaultPolicy:EmptyLinesPolicy;
	public var ignore:Array<EmptyLinesPlace>;
	public var none:Array<EmptyLinesPlace>;
	public var exact:Array<EmptyLinesPlace>;
	public var upto:Array<EmptyLinesPlace>;
	public var atleast:Array<EmptyLinesPlace>;

	var placemap:Map<EmptyLinesPlace, EmptyLinesPolicy>;

	public function new() {
		super(TOKEN);
		max = 1;
		skipSingleLineTypes = true;

		defaultPolicy = NONE;
		ignore = [];
		none = [];
		exact = [];
		upto = [];
		atleast = [];

		categories = [Category.STYLE, Category.CLARITY];
	}

	function buildPolicyMap() {
		placemap = new Map<EmptyLinesPlace, EmptyLinesPolicy>();
		for (place in ignore) placemap.set (place, IGNORE);
		for (place in none) placemap.set (place, NONE);
		for (place in exact) placemap.set (place, EXACT);
		for (place in upto) placemap.set (place, UPTO);
		for (place in atleast) placemap.set (place, ATLEAST);
	}

	function getPolicy(place:EmptyLinesPlace):EmptyLinesPolicy {
		if (placemap.exists(place)) return placemap.get(place);
		return defaultPolicy;
	}

	function isIgnored(places:Array<EmptyLinesPlace>):Bool {
		for (place in places) {
			if (getPolicy(place) != IGNORE) return false;
		}
		return true;
	}

	override function actualRun() {
		buildPolicyMap();
		var emptyLines:ListOfEmptyLines = detectEmptyLines();
		if (max <= 0) max = 1;

		checkPackages(emptyLines);
		checkImports(emptyLines);
		checkTypes(emptyLines);

		checkFile(emptyLines);
		checkFunctions(emptyLines);
		checkComments(emptyLines);
	}

	function detectEmptyLines():ListOfEmptyLines {
		var emptyLines:ListOfEmptyLines = new ListOfEmptyLines();
		for (index in 0...checker.lines.length) {
			if (~/^\s*$/.match(checker.lines[index])) emptyLines.add(index);
		}
		return emptyLines;
	}

	function checkPackages(emptyLines:ListOfEmptyLines) {
		if (isIgnored([BEFOREPACKAGE, AFTERPACKAGE])) return;

		var root:TokenTree = checker.getTokenTree();
		var packages:Array<TokenTree> = root.filter([Kwd(KwdPackage)], ALL);

		for (pack in packages) {
			checkBetweenToken(emptyLines, null, pack, getPolicy(BEFOREPACKAGE), "before package");
			checkBetweenToken(emptyLines, pack, pack.nextSibling, getPolicy(AFTERPACKAGE), "after package");
		}
	}

	function checkImports(emptyLines:ListOfEmptyLines) {
		if (isIgnored([AFTERIMPORTS, BEFOREUSING, BETWEENIMPORTS])) return;

		var root:TokenTree = checker.getTokenTree();
		var imports:Array<TokenTree> = root.filter([Kwd(KwdImport), Kwd(KwdUsing)], ALL);

		if (imports.length <= 0) return;

		var lastImport:TokenTree = imports[imports.length - 1];
		if (lastImport.nextSibling != null) {
			switch (lastImport.nextSibling.tok) {
				case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
					checkBetweenToken(emptyLines, lastImport, lastImport.nextSibling, getPolicy(AFTERIMPORTS), "after imports/using");
				default:
			}
		}

		for (index in 1...imports.length) {
			var imp:TokenTree = imports[index];
			var prev:TokenTree = imp.previousSibling;
			if (prev == null) continue;
			if (imp.is(Kwd(KwdUsing)))  {
				if (prev.is(Kwd(KwdImport)))  {
					checkBetweenToken(emptyLines, prev, imp, getPolicy(BEFOREUSING), "between import and using");
					continue;
				}
			}
			else {
				if (prev.is(Kwd(KwdUsing)))  {
					checkBetweenToken(emptyLines, prev, imp, getPolicy(BEFOREUSING), "between import and using");
					continue;
				}
			}
			switch (prev.tok) {
				case Kwd(KwdImport), Kwd(KwdUsing), Comment(_), CommentLine(_):
					checkBetweenToken(emptyLines, prev, imp, getPolicy(BETWEENIMPORTS), "between imports/using");
				default:
			}
		}
	}

	function checkTypes(emptyLines:ListOfEmptyLines) {
		var root:TokenTree = checker.getTokenTree();
		var types:Array<TokenTree> = root.filter([
			Kwd(KwdAbstract),
			Kwd(KwdClass),
			Kwd(KwdEnum),
			Kwd(KwdInterface),
			Kwd(KwdTypedef)
		], ALL);

		if (types.length <= 0) return;

		checkBetweenTypes(emptyLines, types);

		for (type in types) {
			var pos:Position = type.getPos();
			if (skipSingleLineTypes && (checker.getLinePos(pos.min).line - checker.getLinePos(pos.max).line == 0)) continue;
			switch (type.tok) {
				case Kwd(KwdAbstract): checkAbstract(emptyLines, type);
				case Kwd(KwdClass): checkClass(emptyLines, type);
				case Kwd(KwdEnum):
					if (isIgnored([BEGINENUM, ENDENUM, BETWEENENUMFIELDS, TYPEDEFINITION])) continue;

					checkType(emptyLines, type, getPolicy(BEGINENUM), getPolicy(ENDENUM), function(child:TokenTree, next:TokenTree):PolicyAndWhat {
						return makePolicyAndWhat(getPolicy(BETWEENENUMFIELDS), "between type fields");
					});
				case Kwd(KwdInterface):
					if (isIgnored([BEGININTERFACE, ENDINTERFACE, BETWEENINTERFACEFIELDS, TYPEDEFINITION])) continue;

					checkType(emptyLines, type, getPolicy(BEGININTERFACE), getPolicy(ENDINTERFACE), function(child:TokenTree, next:TokenTree):PolicyAndWhat {
						return makePolicyAndWhat(getPolicy(BETWEENINTERFACEFIELDS), "between type fields");
					});
				case Kwd(KwdTypedef):
					if (isIgnored([BEGINTYPEDEF, ENDTYPEDEF, BETWEENTYPEDEFFIELDS, TYPEDEFINITION])) continue;

					checkType(emptyLines, type, getPolicy(BEGINTYPEDEF), getPolicy(ENDTYPEDEF), function(child:TokenTree, next:TokenTree):PolicyAndWhat {
						return makePolicyAndWhat(getPolicy(BETWEENTYPEDEFFIELDS), "between type fields");
					});
				default:
			}
		}
	}

	function checkBetweenTypes(emptyLines:ListOfEmptyLines, types:Array<TokenTree>) {
		if (isIgnored([BETWEENTYPES])) return;
		for (index in 1...types.length) {
			var type:TokenTree = types[index];
			if (type.previousSibling == null) {
				continue;
			}
			var prevPos:Position = type.previousSibling.getPos();
			if (skipSingleLineTypes && (checker.getLinePos(prevPos.min).line - checker.getLinePos(prevPos.max).line == 0)) continue;

			var startLine:Int = checker.getLinePos(prevPos.max).line;
			var endLine:Int = checker.getLinePos(type.getPos().min).line;
			checkBetween(emptyLines, startLine, endLine, getPolicy(BETWEENTYPES), "between types");
		}
	}

	function checkAbstract(emptyLines:ListOfEmptyLines, typeToken:TokenTree) {
		if (isIgnored([BEGINABSTRACT, ENDABSTRACT, BETWEENABSTRACTMETHODS, AFTERABSTRACTVARS, BETWEENABSTRACTVARS, TYPEDEFINITION])) return;

		checkType(emptyLines, typeToken, getPolicy(BEGINABSTRACT), getPolicy(ENDABSTRACT), function(child:TokenTree, next:TokenTree):PolicyAndWhat {
			var isFuncChild:Bool = child.is(Kwd(KwdFunction));
			var isVarChild:Bool = child.is(Kwd(KwdVar));
			if (!isVarChild && !isFuncChild) return null;
			var type:EmptyLinesFieldType = detectNextFieldType(next);
			if (type == OTHER) return null;
			if (isFuncChild && (type == FUNCTION)) return makePolicyAndWhat(getPolicy(BETWEENABSTRACTMETHODS), "between abstract functions");
			if (isVarChild && (type == FUNCTION)) return makePolicyAndWhat(getPolicy(AFTERABSTRACTVARS), "after abstract vars");
			if (isFuncChild && (type == VAR)) return makePolicyAndWhat(getPolicy(AFTERABSTRACTVARS), "after abstract vars");
			return makePolicyAndWhat(getPolicy(BETWEENABSTRACTVARS), "between abstract vars");
		});
	}

	function checkClass(emptyLines:ListOfEmptyLines, typeToken:TokenTree) {
		var places:Array<EmptyLinesPlace> = [
			BEGINCLASS,
			ENDCLASS,
			BETWEENCLASSMETHODS,
			AFTERCLASSVARS,
			BETWEENCLASSSTATICVARS,
			BETWEENCLASSVARS,
			AFTERCLASSSTATICVARS,
			TYPEDEFINITION
		];
		if (isIgnored(places)) return;

		checkType(emptyLines, typeToken, getPolicy(BEGINCLASS), getPolicy(ENDCLASS), function(child:TokenTree, next:TokenTree):PolicyAndWhat {
			var isFuncChild:Bool = child.is(Kwd(KwdFunction));
			var isVarChild:Bool = child.is(Kwd(KwdVar));
			if (!isVarChild && !isFuncChild) return null;
			var type:EmptyLinesFieldType = detectNextFieldType(next);
			if (type == OTHER) return null;
			if (isFuncChild && (type == FUNCTION)) return makePolicyAndWhat(getPolicy(BETWEENCLASSMETHODS), "between class methods");
			if (isVarChild && (type == FUNCTION)) return makePolicyAndWhat(getPolicy(AFTERCLASSVARS), "after class vars");
			if (isFuncChild && (type == VAR)) return makePolicyAndWhat(getPolicy(AFTERCLASSVARS), "after class vars");

			var isStaticChild:Bool = (child.filter([Kwd(KwdStatic)], FIRST).length > 0);
			var isStaticNext:Bool = (next.filter([Kwd(KwdStatic)], FIRST).length > 0);

			if (isStaticChild && isStaticNext) return makePolicyAndWhat(getPolicy(BETWEENCLASSSTATICVARS), "between class static vars");
			if (!isStaticChild && !isStaticNext) return makePolicyAndWhat(getPolicy(BETWEENCLASSVARS), "between class vars");
			return makePolicyAndWhat(getPolicy(AFTERCLASSSTATICVARS), "after class static vars");
		});
	}

	function detectNextFieldType(field:TokenTree):EmptyLinesFieldType {
		if (field.is(Kwd(KwdFunction))) return FUNCTION;
		if (field.is(Kwd(KwdVar))) return VAR;
		if (!field.isComment()) return OTHER;

		var after:TokenTree = field.nextSibling;
		while (after != null) {
			if (after.is(Kwd(KwdFunction))) return FUNCTION;
			if (after.is(Kwd(KwdVar))) return VAR;
			if (after.isComment()) {
				after = after.nextSibling;
				continue;
			}
			return OTHER;
		}
		return OTHER;
	}

	function checkType(emptyLines:ListOfEmptyLines,
						typeToken:TokenTree,
						beginPolicy:EmptyLinesPolicy,
						endPolicy:EmptyLinesPolicy,
						fieldPolicyProvider:FieldPolicyProvider) {
		var brOpen = findTypeBrOpen(typeToken);
		if (brOpen == null) return;
		checkBetweenToken(emptyLines, typeToken, brOpen, getPolicy(TYPEDEFINITION), "between type definition and left curly");
		var brClose:TokenTree = brOpen.getLastChild();
		var start:Int = checker.getLinePos(brOpen.pos.max).line;
		var end:Int = checker.getLinePos(brClose.pos.min).line;
		if (start == end) return;
		checkLines(emptyLines, beginPolicy, start + 1, start + 1, "after left curly");
		checkLines(emptyLines, endPolicy, end - 1, end - 1, "before right curly");
		for (child in brOpen.children) {
			switch (child.tok) {
				case Comment(_):
				case CommentLine(_):
				case At:
				default:
					var next:TokenTree = child.nextSibling;
					if (next == null) continue;
					if (next.is(BrClose)) continue;
					var policyAndWhat:PolicyAndWhat = fieldPolicyProvider(child, next);
					if (policyAndWhat == null) continue;
					checkBetweenFullToken(emptyLines, child, next, policyAndWhat.policy, policyAndWhat.whatMsg);
			}
		}
	}

	function findTypeBrOpen(parent:TokenTree):TokenTree {
		if (parent == null) return null;
		var brOpens:Array<TokenTree> = parent.filterCallback(function (tok:TokenTree, depth:Int):FilterResult {
			return switch (tok.tok) {
				case BrOpen: FOUND_SKIP_SUBTREE;
				default: GO_DEEPER;
			}
		});
		if (brOpens.length <= 0) return null;
		return brOpens[0];
	}

	function checkFile(emptyLines:ListOfEmptyLines) {
		if (isIgnored([ANYWHEREINFILE, BEFOREFILEEND])) return;

		var ranges:Array<EmptyLineRange> = emptyLines.getRanges(0, checker.lines.length);
		for (range in ranges) {
			var line:Int = 0;
			switch (range) {
				case NONE:
				case SINGLE(l): line = l;
				case RANGE(start, end): line = end;
			}
			var result:EmptyLineRange = emptyLines.checkRange(getPolicy(ANYWHEREINFILE), max, range, line);
			logEmptyRange(getPolicy(ANYWHEREINFILE), "anywhere in file", result);
		}

		var range:EmptyLineRange = NONE;
		if (ranges.length > 0) {
			var lastRange:EmptyLineRange = ranges[ranges.length - 1];
			switch (lastRange) {
				case NONE:
				case SINGLE(line):
					if (line == checker.lines.length - 1) range = lastRange;
				case RANGE(start, end):
					if (end == checker.lines.length - 1) range = lastRange;
			}
		}
		var result:EmptyLineRange = emptyLines.checkRange(getPolicy(BEFOREFILEEND), max, range, checker.lines.length - 1);
		logEmptyRange(getPolicy(BEFOREFILEEND), "before file end", result);
	}

	function checkFunctions(emptyLines:ListOfEmptyLines) {
		if (isIgnored([INFUNCTION, AFTERLEFTCURLY, BEFORERIGHTCURLY])) return;

		var root:TokenTree = checker.getTokenTree();
		var funcs:Array<TokenTree> = root.filter([Kwd(KwdFunction)], ALL);

		if (funcs.length <= 0) return;

		for (func in funcs) {
			var pos:Position = func.getPos();
			var start:Int = checker.getLinePos(pos.min).line;
			var end:Int = checker.getLinePos(pos.max).line;
			checkLines(emptyLines, getPolicy(INFUNCTION), start, end, "inside functions", true);

			var brOpen:Array<TokenTree> = func.filter([BrOpen], ALL);
			for (open in brOpen) {
				var close:TokenTree = open.getLastChild();
				if (close == null) continue;
				var start:Int = checker.getLinePos(open.pos.max).line;
				var end:Int = checker.getLinePos(close.pos.min).line;
				if (start == end) continue;
				checkLines(emptyLines, getPolicy(AFTERLEFTCURLY), start + 1, start + 1, "after left curly");
				checkLines(emptyLines, getPolicy(BEFORERIGHTCURLY), end - 1, end - 1, "before right curly");
			}
		}
	}

	function checkComments(emptyLines:ListOfEmptyLines) {
		if (isIgnored([AFTERMULTILINECOMMENT, AFTERSINGLELINECOMMENT])) return;

		var root:TokenTree = checker.getTokenTree();
		var comments:Array<TokenTree> = root.filterCallback(function (tok:TokenTree, depth:Int):FilterResult {
			return switch (tok.tok) {
				case Comment(_): FOUND_SKIP_SUBTREE;
				case CommentLine(_): FOUND_SKIP_SUBTREE;
				default: GO_DEEPER;
			}
		});
		for (comment in comments) {
			var line:Int = checker.getLinePos(comment.pos.min).line;
			if (!~/^\s*(\/\/|\/\*)/.match(checker.lines[line])) continue;
			line = checker.getLinePos(comment.getPos().max).line + 1;
			switch (comment.tok) {
				case Comment(_):
					checkLines(emptyLines, getPolicy(AFTERMULTILINECOMMENT), line, line, "after comment");
				case CommentLine(_):
					checkLines(emptyLines, getPolicy(AFTERSINGLELINECOMMENT), line, line, "after comment");
				default:
			}
		}
	}

	function checkLines(emptyLines:ListOfEmptyLines, policy:EmptyLinesPolicy, start:Int, end:Int, whatMsg:String, tolerateEmptyRange:Bool = false) {
		var ranges:Array<EmptyLineRange> = emptyLines.getRanges(start, end);
		if (!tolerateEmptyRange && (ranges.length <= 0)) ranges = [NONE];
		for (range in ranges) {
			var result:EmptyLineRange = emptyLines.checkRange(policy, max, range, end);
			logEmptyRange(policy, whatMsg, result);
		}
	}

	function checkBetweenFullToken(emptyLines:ListOfEmptyLines, firstToken:TokenTree, secondToken:TokenTree, policy:EmptyLinesPolicy, whatMsg:String) {
		var lineStart:Int = 0;
		var lineEnd:Int = checker.lines.length;
		if (firstToken != null) {
			lineStart = checker.getLinePos(firstToken.getPos().max).line;
		}
		if (secondToken != null) {
			lineEnd = checker.getLinePos(secondToken.getPos().min).line;
		}
		checkBetween(emptyLines, lineStart, lineEnd, policy, whatMsg);
	}

	function checkBetweenToken(emptyLines:ListOfEmptyLines, firstToken:TokenTree, secondToken:TokenTree, policy:EmptyLinesPolicy, whatMsg:String) {
		var lineStart:Int = 0;
		var lineEnd:Int = checker.lines.length;
		if (firstToken != null) {
			lineStart = checker.getLinePos(firstToken.pos.max).line;
		}
		if (secondToken != null) {
			lineEnd = checker.getLinePos(secondToken.pos.min).line;
		}
		checkBetween(emptyLines, lineStart, lineEnd, policy, whatMsg);
	}

	function checkBetween(emptyLines:ListOfEmptyLines, lineStart:Int, lineEnd:Int, policy:EmptyLinesPolicy, whatMsg:String) {
		if (lineStart < 0) lineStart = 0;
		if (lineEnd < 0) lineEnd = checker.lines.length;
		var result:EmptyLineRange = emptyLines.checkPolicySingleRange(policy, max, lineStart, lineEnd);
		logEmptyRange(policy, whatMsg, result);
	}

	function makePolicyAndWhat(policy:EmptyLinesPolicy, whatMsg:String):PolicyAndWhat {
		return {
			policy: policy,
			whatMsg: whatMsg
		};
	}

	function logEmptyRange(policy:EmptyLinesPolicy, whatMsg:String, range:EmptyLineRange) {
		if (range == null) return;
		switch (range) {
			case NONE:
			case SINGLE(line):
				if (isLineSuppressed(line)) return;
				log(formatMessage(policy, whatMsg), line + 1, 0);
			case RANGE(start, end):
				if (isLineSuppressed(start)) return;
				var length:Int = checker.linesIdx[end].r - checker.linesIdx[start].l;
				log(formatMessage(policy, whatMsg), start + 1, 0, length);
		}
	}

	function formatMessage(policy:EmptyLinesPolicy, what:String):String {
		var line:String = "lines";
		if (max == 1) line = "line";
		return switch (policy) {
			case IGNORE: "ignored empty lines " + what;
			case NONE: "should not have empty line(s) " + what;
			case EXACT: 'should have exactly $max empty $line $what';
			case UPTO: 'should have upto $max empty $line $what';
			case ATLEAST: 'should have at least $max empty $line $what';
		}
	}

	override public function detectableInstances():DetectableInstances {
		return [{
			fixed: [{
				propertyName: "max",
				value: 1
			}],
			properties: [{
				"propertyName": "skipSingleLineTypes",
				"values": [false, true]
			},
			{
				"propertyName": "defaultPolicy",
				"values": ["none", "exact", "upto", "atleast", "ignore"]
			},
			{
				"propertyName": "none",
				"values": [[
					BEFOREPACKAGE,
					BETWEENIMPORTS,
					BEFOREUSING,
					TYPEDEFINITION,
					AFTERLEFTCURLY,
					BEFORERIGHTCURLY
				]]
			}]
		}];
	}
}

typedef FieldPolicyProvider = TokenTree -> TokenTree -> PolicyAndWhat;

typedef PolicyAndWhat = {
	var policy:EmptyLinesPolicy;
	var whatMsg:String;
}

@:enum
abstract EmptyLinesPolicy(String) {
	var IGNORE = "ignore";
	var NONE = "none";
	var EXACT = "exact";
	var UPTO = "upto";
	var ATLEAST = "atleast";
}

enum EmptyLinesFieldType {
	VAR;
	FUNCTION;
	OTHER;
}

@:enum
abstract EmptyLinesPlace(String) {
	var BEFOREPACKAGE = "beforePackage";
	var AFTERPACKAGE = "afterPackage";
	var BETWEENIMPORTS = "betweenImports";
	var BEFOREUSING = "beforeUsing";
	var AFTERIMPORTS = "afterImports";

	var ANYWHEREINFILE = "anywhereInFile";
	var BETWEENTYPES = "betweenTypes";
	var BEFOREFILEEND = "beforeFileEnd";
	var INFUNCTION = "inFunction";
	var AFTERLEFTCURLY = "afterLeftCurly";
	var BEFORERIGHTCURLY = "beforeRightCurly";
	var TYPEDEFINITION = "typeDefinition";

	var BEGINCLASS = "beginClass";
	var ENDCLASS = "endClass";
	var AFTERCLASSSTATICVARS = "afterClassStaticVars";
	var AFTERCLASSVARS = "afterClassVars";
	var BETWEENCLASSSTATICVARS = "betweenClassStaticVars";
	var BETWEENCLASSVARS = "betweenClassVars";
	var BETWEENCLASSMETHODS = "betweenClassMethods";

	var BEGINABSTRACT = "beginAbstract";
	var ENDABSTRACT = "endAbstract";
	var AFTERABSTRACTVARS = "afterAbstractVars";
	var BETWEENABSTRACTVARS = "betweenAbstractVars";
	var BETWEENABSTRACTMETHODS = "betweenAbstractMethods";

	var BEGININTERFACE = "beginInterface";
	var ENDINTERFACE = "endInterface";
	var BETWEENINTERFACEFIELDS = "betweenInterfaceFields";

	var BEGINENUM = "beginEnum";
	var ENDENUM = "endEnum";
	var BETWEENENUMFIELDS = "betweenEnumFields";

	var BEGINTYPEDEF = "beginTypedef";
	var ENDTYPEDEF = "endTypedef";
	var BETWEENTYPEDEFFIELDS = "betweenTypedefFields";

	var AFTERSINGLELINECOMMENT = "afterSingleLineComment";
	var AFTERMULTILINECOMMENT = "afterMultiLineComment";
}