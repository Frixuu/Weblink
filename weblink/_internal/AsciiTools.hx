package weblink._internal;

using Lambda;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;
#else
@:build(weblink._internal.AsciiTools.populate())
#end
final class AsciiTools {
	#if !macro
	public static inline function isCharAllowedInToken(char:Int):Bool {
		return AsciiTools.CHARS_ALLOWED_IN_TOKENS[char];
	}
	#end

	public static inline function isControl(char:Int):Bool {
		return char < 32 || char == 127;
	}

	public static inline function isPrintable(char:Int):Bool {
		return char >= 32 && char <= 126;
	}

	#if macro
	private static function makeArray<T>(len:Int, value:T):Array<T> {
		final arr = new Array<T>();
		arr.resize(len);
		for (i in 0...len) {
			arr[i] = value;
		}
		return arr;
	}

	public static function populate():Array<Field> {
		final pos = Context.currentPos();
		final fields = Context.getBuildFields();

		final digits = makeArray(128, false);
		for (i in "0".code...("9".code + 1)) {
			digits[i] = true;
		}

		final letters = makeArray(128, false);
		for (i in "A".code...("Z".code + 1)) {
			letters[i] = true;
		}
		for (i in "a".code...("z".code + 1)) {
			letters[i] = true;
		}

		final allowed = makeArray(128, false);
		allowed["!".code] = true;
		allowed["#".code] = true;
		allowed["$".code] = true;
		allowed["%".code] = true;
		allowed["&".code] = true;
		allowed["'".code] = true;
		allowed["*".code] = true;
		allowed["+".code] = true;
		allowed["-".code] = true;
		allowed[".".code] = true;
		allowed["^".code] = true;
		allowed["_".code] = true;
		allowed["`".code] = true;
		allowed["|".code] = true;
		allowed["~".code] = true;
		for (i in 0...128) {
			if (digits[i] || letters[i]) {
				allowed[i] = true;
			}
		}

		fields.push({
			pos: pos,
			name: "CHARS_ALLOWED_IN_TOKENS",
			doc: "Lookup table for US_ASCII chars allowed in tokens (according to RFC 7230)",
			access: [APrivate, AStatic],
			kind: FVar((macro :Array<Bool>), {
				final exprs = [for (v in allowed) macro $v{v}];
				macro $a{exprs};
			}),
		});

		return fields;
	}
	#end
}
