@JS()
library emscripten_module;

import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../../../../wasm_ffi_core.dart';
import '../../annotations.dart';
import '../../memory.dart';
import '../../type_utils.dart';
import '../module.dart';
import '../table.dart';

@JS('globalThis')
external Object get _globalThis;

@JS('Object.entries')
external List? _entries(Object? o);

@JS()
@anonymous
class _EmscriptenModuleJs {
  external Uint8List? get wasmBinary;
  // ignore: non_constant_identifier_names
  external Uint8List? get HEAPU8;

  external Object? get asm; // Emscripten <3.1.44
  external Object? get wasmExports; // Emscripten >=3.1.44

  // Must have an unnamed factory constructor with named arguments.
  external factory _EmscriptenModuleJs({Uint8List? wasmBinary});
}

const String _github = r'https://github.com/vm75/wasm_ffi';
String _adu(WasmSymbol? original, WasmSymbol? tried) =>
    'CRITICAL EXCEPTION! Address double use! This should never happen, please report this issue on github immediately at $_github'
    '\r\nOriginal: $original'
    '\r\nTried: $tried';

typedef _Malloc = int Function(int size);
typedef _Free = void Function(int address);

FunctionDescription _fromWasmFunction(String name, Function func) {
  String? s = getProperty(func, 'name');
  if (s != null) {
    int? index = int.tryParse(s);
    if (index != null) {
      int? length = getProperty(func, 'length');
      if (length != null) {
        return FunctionDescription(
            tableIndex: index,
            name: name,
            function: func,
            argumentCount: length);
      } else {
        throw ArgumentError('$name does not seem to be a function symbol!');
      }
    } else {
      throw ArgumentError('$name does not seem to be a function symbol!');
    }
  } else {
    throw ArgumentError('$name does not seem to be a function symbol!');
  }
}

/// Documentation is in `emscripten_module_stub.dart`!
@extra
class EmscriptenModule extends Module {
  static Function _moduleFunction(String moduleName) {
    Function? moduleFunction = getProperty(_globalThis, moduleName);
    if (moduleFunction != null) {
      return moduleFunction;
    } else {
      throw StateError('Could not find a emscripten module named $moduleName');
    }
  }

  /// Documentation is in `emscripten_module_stub.dart`!
  static Future<EmscriptenModule> compile(
      Uint8List wasmBinary, String moduleName,
      {void Function(_EmscriptenModuleJs)? preinit}) async {
    Function moduleFunction = _moduleFunction(moduleName);
    _EmscriptenModuleJs module = _EmscriptenModuleJs(wasmBinary: wasmBinary);
    Object? o = moduleFunction(module);
    preinit?.call(module);
    if (o != null) {
      await promiseToFuture(o);
      return EmscriptenModule._fromJs(module);
    } else {
      throw StateError('Could not instantiate an emscripten module!');
    }
  }

  final _EmscriptenModuleJs _emscriptenModuleJs;
  final List<WasmSymbol> _exports;
  final _Malloc _malloc;
  final _Free _free;
  final Table? _indirectFunctionTable;

  @override
  List<WasmSymbol> get exports => _exports;

  @override
  Table? get indirectFunctionTable => _indirectFunctionTable;

  EmscriptenModule._(this._emscriptenModuleJs, this._exports,
      this._indirectFunctionTable, this._malloc, this._free);

  factory EmscriptenModule._fromJs(_EmscriptenModuleJs module) {
    Object? asm = module.wasmExports ?? module.asm;
    if (asm != null) {
      Map<int, WasmSymbol> knownAddresses = {};
      _Malloc? malloc;
      _Free? free;
      List<WasmSymbol> exports = [];
      List? entries = _entries(asm);
      Table? indirectFunctionTable;
      if (entries != null) {
        for (dynamic entry in entries) {
          if (entry is List) {
            Object value = entry.last;
            if (value is int) {
              Global g = Global(address: value, name: entry.first as String);
              if (knownAddresses.containsKey(value) &&
                  knownAddresses[value] is! Global) {
                throw StateError(_adu(knownAddresses[value], g));
              }
              knownAddresses[value] = g;
              exports.add(g);
            } else if (value is Function) {
              FunctionDescription description =
                  _fromWasmFunction(entry.first as String, value);
              // It might happen that there are two different c functions that do nothing else than calling the same underlying c function
              // In this case, a compiler might substitute both functions with the underlying c function
              // So we got two functions with different names at the same table index
              // So it is actually ok if there are two things at the same address, as long as they are both functions
              if (knownAddresses.containsKey(description.tableIndex) &&
                  knownAddresses[description.tableIndex]
                      is! FunctionDescription) {
                throw StateError(
                    _adu(knownAddresses[description.tableIndex], description));
              }
              knownAddresses[description.tableIndex] = description;
              exports.add(description);
              if (description.name == 'malloc') {
                malloc = description.function as _Malloc;
              } else if (description.name == 'free') {
                free = description.function as _Free;
              }
            } else if (value is Table &&
                entry.first as String == "__indirect_function_table") {
              indirectFunctionTable = value;
            } else if (entry.first as String == "memory") {
              // ignore memory object
            } else {
              // ignore unknown entries
              // throw StateError(
              //     'Warning: Unexpected value in entry list! Entry is $entry, value is $value (of type ${value.runtimeType})');
            }
          } else {
            throw StateError('Unexpected entry in entries(Module[\'asm\'])!');
          }
        }
        if (malloc != null) {
          if (free != null) {
            return EmscriptenModule._(
                module, exports, indirectFunctionTable, malloc, free);
          } else {
            throw StateError('Module does not export the free function!');
          }
        } else {
          throw StateError('Module does not export the malloc function!');
        }
      } else {
        throw StateError(
            'JavaScript error: Could not access entries of Module[\'asm\']!');
      }
    } else {
      throw StateError(
          'Could not access Module[\'asm\'], are your sure your module was compiled using emscripten?');
    }
  }

  @override
  void free(int pointer) => _free(pointer);

  @override
  ByteBuffer get heap => _getHeap();
  ByteBuffer _getHeap() {
    Uint8List? h = _emscriptenModuleJs.HEAPU8;
    if (h != null) {
      return h.buffer;
    } else {
      throw StateError('Unexpected memory error!');
    }
  }

  @override
  int malloc(int size) => _malloc(size);

  /// Looks up a symbol in the DynamicLibrary and returns its address in memory.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  ///
  /// While this method checks if the underyling wasm symbol is a actually
  /// a function when you lookup a [NativeFunction]`<T>`, it does not check if
  /// the return type and parameters of `T` match the wasm function.
  @override
  Pointer<T> lookup<T extends NativeType>(String name, Memory memory) {
    WasmSymbol symbol = symbolByName(memory, name);
    if (isNativeFunctionType<T>()) {
      if (symbol is FunctionDescription) {
        return Pointer<T>.fromAddress(symbol.tableIndex, memory);
      } else {
        throw ArgumentError(
            'Tried to look up $name as a function, but it seems it is NOT a function!');
      }
    } else {
      return Pointer<T>.fromAddress(symbol.address, memory);
    }
  }

  /// Checks whether this dynamic library provides a symbol with the given
  /// name.
  @override
  bool providesSymbol(String symbolName) => throw UnimplementedError();

  @override
  F lookupFunction<T extends Function, F extends Function>(
      String name, Memory memory) {
    return lookup<NativeFunction<T>>(name, memory).asFunction<F>();
  }
  // _EmscriptenModuleJs get module => _emscriptenModuleJs;
}