
var WasmFfi = (() => {
  var _scriptDir = typeof document !== 'undefined' && document.currentScript ? document.currentScript.src : undefined;
  if (typeof __filename !== 'undefined') _scriptDir = _scriptDir || __filename;
  return (
function(WasmFfi = {})  {



  return WasmFfi.ready
}

);
})();
if (typeof exports === 'object' && typeof module === 'object')
  module.exports = WasmFfi;
else if (typeof define === 'function' && define['amd'])
  define([], function() { return WasmFfi; });
else if (typeof exports === 'object')
  exports["WasmFfi"] = WasmFfi;