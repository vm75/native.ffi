// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'package:wasm_ffi/ffi_bridge.dart' as ffi;

/// Bindings for Wasm.
class WasmFfiBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  WasmFfiBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  WasmFfiBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// hello world
  ffi.Pointer<ffi.Char> hello(
    ffi.Pointer<ffi.Char> text,
  ) {
    return _hello(
      text,
    );
  }

  late final _helloPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>)>>('hello');
  late final _hello = _helloPtr
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>)>();

  /// free up the memory allocated by the library
  void freeMemory(
    ffi.Pointer<ffi.Char> buffer,
  ) {
    return _freeMemory(
      buffer,
    );
  }

  late final _freeMemoryPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Char>)>>(
          'freeMemory');
  late final _freeMemory =
      _freeMemoryPtr.asFunction<void Function(ffi.Pointer<ffi.Char>)>();

  /// size of an int
  int intSize() {
    return _intSize();
  }

  late final _intSizePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('intSize');
  late final _intSize = _intSizePtr.asFunction<int Function()>();

  /// size of a bool
  int boolSize() {
    return _boolSize();
  }

  late final _boolSizePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('boolSize');
  late final _boolSize = _boolSizePtr.asFunction<int Function()>();

  /// size of a pointer
  int pointerSize() {
    return _pointerSize();
  }

  late final _pointerSizePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('pointerSize');
  late final _pointerSize = _pointerSizePtr.asFunction<int Function()>();
}
