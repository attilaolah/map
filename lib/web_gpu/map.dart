import 'dart:async';
import 'dart:html';

import 'triangle.dart';
import 'support.dart';

import 'package:resize_observer/resize_observer.dart' as ro;


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
    final CanvasElement c = Element.canvas() as CanvasElement;
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
  late GPUExtent3DDict _size;
  late final String _format;

  Future<void> init() async {
    _adapter = await window.navigator.gpu.requestAdapter();
    _device = await _adapter.requestDevice();
    _format = _ctx.getPreferredFormat(_adapter);

    configure();
    ro.ResizeObserver.observe(_canvas, (Element el, num x, num y, num width, num height, num top, num bottom, num left, num right) {
      _size = GPUExtent3DDict(
        width: (width * _dpr).floor(),
        height: (height * _dpr).floor(),
      );
      configure();
    });
  }

  void configure() {
    _ctx.configure(GPUCanvasConfiguration(
      device: _device,
      format: _format,
      size: _size,
    ));
  }

  void drawTriangle() {
    Triangle(
      ctx: _ctx,
      device: _device,
      format: _format,
    ).draw();
  }
}
