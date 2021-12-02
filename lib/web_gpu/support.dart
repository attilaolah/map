@JS()
library web_gpu;

import 'dart:html';
import 'dart:js_util';

import 'package:js/js.dart';

extension NavigatorGPU on Navigator {
  GPU get gpu {
    return GPU(getProperty(this, 'gpu'));
  }
}

extension CanvasElementWebGPU on CanvasElement {
  GPUCanvasContext getContextGPU() {
    Object? ctx = getContext('webgpu');
    if (ctx == null) {
      throw Exception('WebGPU canvas context not available.');
    }
    return GPUCanvasContext(ctx);
  }
}


class GPU {
  GPU(this._gpu);
  final dynamic _gpu;

  Future<GPUAdapter> requestAdapter() async {
    dynamic x = await promiseToFuture(callMethod(_gpu, 'requestAdapter', []));
    GPUAdapter a = GPUAdapter(x);
    return a;
  }
}

class GPUAdapter {
  GPUAdapter(this._js);
  final dynamic _js;

  Future<GPUDevice> requestDevice() async {
    return GPUDevice(await promiseToFuture(callMethod(_js, 'requestDevice', [])));
  }
}

class GPUDevice {
  GPUDevice(this._js);
  final dynamic _js;

  GPUQueue get queue {
    return getProperty(_js, 'queue');
  }
  GPUCommandEncoder createCommandEncoder() {
    return callMethod(_js, 'createCommandEncoder', []);
  }
  GPURenderPipeline createRenderPipeline(GPURenderPipelineDescriptor descriptor) {
    return callMethod(_js, 'createRenderPipeline', [descriptor]);
  }
  GPUShaderModule createShaderModule(GPUShaderModuleDescriptor descriptor) {
    return callMethod(_js, 'createShaderModule', [descriptor]);
  }
}

@JS()
class GPUQueue {
  @JS()
  external submit(List<GPUCommandBuffer> commandBuffers);
}

@JS()
class GPUCommandBuffer {}

@JS()
class GPUCommandEncoder {
  @JS()
  external GPURenderPassEncoder beginRenderPass(GPURenderPassDescriptor descriptor);
  @JS()
  external GPUCommandBuffer finish([GPUCommandBufferDescriptor? descriptor]);
}

@JS()
class GPURenderPassEncoder {
  @JS()
  external setPipeline(GPURenderPipeline pipeline);
  @JS()
  external draw(int vertexCount, int instanceCount, int firstVertex, int firstInstance);
  @JS()
  external endPass();
}

@JS()
class GPURenderPipeline {}

@JS()
class GPUShaderModule {}

class GPUCanvasContext {
  GPUCanvasContext(this._js);
  final dynamic _js;

  configure(GPUCanvasConfiguration configuration) {
    // TODO: Avoid the use of [jsify()] (needed for the 'device' key below).
    callMethod(_js, 'configure', [jsify(<String, dynamic>{
      'device': configuration.device._js,
      'format': configuration.format,
      'size': configuration.size,
    })]);
  }
  String getPreferredFormat(GPUAdapter adapter) {
    return callMethod(_js, 'getPreferredFormat', [adapter._js]);
  }
  GPUTexture getCurrentTexture() {
    return callMethod(_js, 'getCurrentTexture', []);
  }
}

@JS()
class GPUTexture {
  @JS()
  external GPUTextureView createView([GPUTextureViewDescriptor? descriptor]);
}

@JS()
class GPUTextureView {}

@JS()
@anonymous
class GPUCanvasConfiguration {
  // https://www.w3.org/TR/webgpu/#dictdef-gpucanvasconfiguration
  external GPUDevice device;
  external String format;  // TODO: enum!
  external GPUExtent3DDict size;

  @JS()
  external factory GPUCanvasConfiguration({
    required GPUDevice device,
    required String format,  // TODO: enum!
    GPUExtent3DDict size,
  });
}

@JS()
@anonymous
class GPUExtent3DDict {
  external int get width;
  external int get height;

  @JS()
  external factory GPUExtent3DDict({
    required int width,
    int height,
  });
}

@JS()
@anonymous
class GPURenderPipelineDescriptor {
  external GPUVertexState get vertex;
  external GPUPrimitiveState get primitive;
  external GPUFragmentState get fragment;

  @JS()
  external factory GPURenderPipelineDescriptor({
    required GPUVertexState vertex,
    GPUPrimitiveState primitive,
    GPUFragmentState fragment,
  });
}

@JS()
@anonymous
class GPUVertexState extends GPUProgrammableStage {
  @JS()
  external factory GPUVertexState({
    required GPUShaderModule module,
    required String entryPoint,
  });
}


@JS()
@anonymous
class GPUProgrammableStage {
  external GPUShaderModule get module;
  external String get entryPoint;

  @JS()
  external factory GPUProgrammableStage({
    required GPUShaderModule module,
    required String entryPoint,
  });
}

@JS()
@anonymous
class GPUShaderModuleDescriptor {
  external String get code;

  @JS()
  external factory GPUShaderModuleDescriptor({
    required String code,
  });
}

@JS()
@anonymous
class GPUPrimitiveState {
  external String get topology;

  @JS()
  external factory GPUPrimitiveState({
    required String topology,
  });
}

@JS()
@anonymous
class GPUFragmentState extends GPUProgrammableStage {
  external List<GPUColorTargetState> get targets;

  @JS()
  external factory GPUFragmentState({
    required GPUShaderModule module,
    required String entryPoint,
    required List<GPUColorTargetState> targets,
  });
}

@JS()
@anonymous
class GPUColorTargetState {
  external String get format;

  @JS()
  external factory GPUColorTargetState({
    required String format,
  });
}

@JS()
@anonymous
class GPUTextureViewDescriptor {}

@JS()
@anonymous
class GPURenderPassDescriptor {
  external List<GPURenderPassColorAttachment> get colorAttachments;

  @JS()
  external factory GPURenderPassDescriptor({
    required List<GPURenderPassColorAttachment> colorAttachments,
  });
}

@JS()
@anonymous
class GPURenderPassColorAttachment {
  external GPUTextureView get view;
  external GPUColor get loadValue;
  external String get storeOp;

  @JS()
  external factory GPURenderPassColorAttachment({
    required GPUTextureView view,
    required GPUColor loadValue,
    required String storeOp,
  });
}

@JS()
@anonymous
class GPUColor {
  external double get r;
  external double get g;
  external double get b;
  external double get a;

  @JS()
  external factory GPUColor({
    required double r,
    required double g,
    required double b,
    required double a,
  });
}

@JS()
@anonymous
class GPUCommandBufferDescriptor {}
