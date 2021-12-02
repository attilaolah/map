import 'dart:async';
import 'dart:html';

import 'triangle.dart';
import 'support.dart';


class WebGPUMap {
  WebGPUMap() {
    // Inject the canvas element.
    // This must be done first so that client{Width,Height} would become available.
    document.body?.insertBefore(_canvas, document.body?.firstChild);

    _ctx = _canvas.getContextGPU();
    _dpr = window.devicePixelRatio.toDouble();
    _size = GPUExtent3DDict(
      width: (_canvas.clientWidth * _dpr).floor(),
      height: (_canvas.clientHeight * _dpr).floor(),
    );

    // Remove the Flutter loader animation element.
    document.dispatchEvent(Event('dart-app-ready'));
  }

  final CanvasElement _canvas = () {
    CanvasElement c = Element.canvas() as CanvasElement;
    // Apply styles to the canvas before injecting.
    c.style.width = '100vw';
    c.style.height = '100vh';
    return c;
  }();
  late final GPUCanvasContext _ctx;

  late final GPUAdapter _adapter;
  late final GPUDevice _device;

  // Device pixel ratio (non-configurable).
  late final double _dpr;
  late final GPUExtent3DDict _size;
  late final String _format;

  Future<void> init() async {
    _adapter = await window.navigator.gpu.requestAdapter();
    _device = await _adapter.requestDevice();
    _format = _ctx.getPreferredFormat(_adapter);
  }

  void configure() {
    _ctx.configure(GPUCanvasConfiguration(
      device: _device,
      format: _format,
      size: _size,
    ));
  }

  void drawTriangle() {
    final triangle = Triangle(
      ctx: _ctx,
      device: _device,
      format: _format,
    );
    triangle.draw();
  }
}
