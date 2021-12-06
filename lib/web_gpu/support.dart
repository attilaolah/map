@JS()
library web_gpu;

import 'dart:html';
import 'dart:js_util';

import 'package:js/js.dart';

extension NavigatorGPU on Navigator {
  GPU get gpu {
    return GPU(getProperty(this, 'gpu') as Object);
  }
}

extension CanvasElementWebGPU on CanvasElement {
  GPUCanvasContext getContextGPU() {
    final Object? ctx = getContext('webgpu');
    if (ctx == null) {
      throw Exception('WebGPU canvas context not available.');
    }
    return GPUCanvasContext(ctx);
  }
}


class GPU {
  GPU(final this._gpu);
  final Object _gpu;

  Future<GPUAdapter> requestAdapter() async {
    return GPUAdapter(await promiseToFuture(
      callMethod(_gpu, 'requestAdapter', []) as Object));
  }
}

class GPUAdapter {
  GPUAdapter(final this._js);
  final Object _js;

  Future<GPUDevice> requestDevice() async {
    return GPUDevice(await promiseToFuture(
      callMethod(_js, 'requestDevice', []) as Object));
  }
}

class GPUDevice {
  GPUDevice(final this._js);
  final Object _js;

  GPUQueue get queue {
    return getProperty(_js, 'queue') as GPUQueue;
  }
  GPUCommandEncoder createCommandEncoder() {
    return callMethod(_js, 'createCommandEncoder', []) as GPUCommandEncoder;
  }
  GPURenderPipeline createRenderPipeline(final GPURenderPipelineDescriptor descriptor) {
    return callMethod(_js, 'createRenderPipeline', [descriptor]) as GPURenderPipeline;
  }
  GPUShaderModule createShaderModule(final GPUShaderModuleDescriptor descriptor) {
    return callMethod(_js, 'createShaderModule', [descriptor]) as GPUShaderModule;
  }
}

@JS()
class GPUQueue {
  @JS()
  external void submit(final List<GPUCommandBuffer> commandBuffers);
}

@JS()
class GPUCommandBuffer {}

@JS()
class GPUCommandEncoder {
  @JS()
  external GPURenderPassEncoder beginRenderPass(final GPURenderPassDescriptor descriptor);
  @JS()
  external GPUCommandBuffer finish([final GPUCommandBufferDescriptor? descriptor]);
}

@JS()
class GPURenderPassEncoder {
  @JS()
  external void setPipeline(final GPURenderPipeline pipeline);
  @JS()
  external void draw(final int vertexCount, final int instanceCount, final int firstVertex, final int firstInstance);
  @JS()
  external void endPass();
}

@JS()
class GPURenderPipeline {}

@JS()
class GPUShaderModule {}

class GPUCanvasContext {
  GPUCanvasContext(final this._js);
  final Object _js;

  void configure(final GPUCanvasConfiguration configuration) {
    // TODO: Avoid the use of [jsify()] (needed for the 'device' key below).
    callMethod(_js, 'configure', [jsify(<String, dynamic>{
      'device': configuration.device._js,
      'format': configuration.format,
      'size': configuration.size,
    })]);
  }
  String getPreferredFormat(final GPUAdapter adapter) {
    return callMethod(_js, 'getPreferredFormat', [adapter._js]) as String;
  }
  GPUTexture getCurrentTexture() {
    return callMethod(_js, 'getCurrentTexture', []) as GPUTexture;
  }
}

@JS()
class GPUTexture {
  @JS()
  external GPUTextureView createView([final GPUTextureViewDescriptor? descriptor]);
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
    required final GPUDevice device,
    required final String format,  // TODO: enum!
    final GPUExtent3DDict size,
  });
}

@JS()
@anonymous
class GPUExtent3DDict {
  external int get width;
  external int get height;

  @JS()
  external factory GPUExtent3DDict({
    required final int width,
    final int height,
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
    required final GPUVertexState vertex,
    final GPUPrimitiveState primitive,
    final GPUFragmentState fragment,
  });
}

@JS()
@anonymous
class GPUVertexState extends GPUProgrammableStage {
  @JS()
  external factory GPUVertexState({
    required final GPUShaderModule module,
    required final String entryPoint,
  });
}


@JS()
@anonymous
class GPUProgrammableStage {
  external GPUShaderModule get module;
  external String get entryPoint;

  @JS()
  external factory GPUProgrammableStage({
    required final GPUShaderModule module,
    required final String entryPoint,
  });
}

@JS()
@anonymous
class GPUShaderModuleDescriptor {
  external String get code;

  @JS()
  external factory GPUShaderModuleDescriptor({
    required final String code,
  });
}

@JS()
@anonymous
class GPUPrimitiveState {
  external String get topology;

  @JS()
  external factory GPUPrimitiveState({
    required final String topology,
  });
}

@JS()
@anonymous
class GPUFragmentState extends GPUProgrammableStage {
  external List<GPUColorTargetState> get targets;

  @JS()
  external factory GPUFragmentState({
    required final GPUShaderModule module,
    required final String entryPoint,
    required final List<GPUColorTargetState> targets,
  });
}

@JS()
@anonymous
class GPUColorTargetState {
  external String get format;

  @JS()
  external factory GPUColorTargetState({
    required final String format,
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
    required final List<GPURenderPassColorAttachment> colorAttachments,
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
    required final GPUTextureView view,
    required final GPUColor loadValue,
    required final String storeOp,
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
    required final double r,
    required final double g,
    required final double b,
    required final double a,
  });
}

@JS()
@anonymous
class GPUCommandBufferDescriptor {}
