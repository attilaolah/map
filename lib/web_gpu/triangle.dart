import 'dart:html';

import 'support.dart';


class Triangle {
  Triangle({
    required this.ctx,
    required this.device,
    required this.format,
  });

  GPUCanvasContext ctx;
  GPUDevice device;
  String format;

  void draw() {
    final GPURenderPipeline pipeline = device.createRenderPipeline(
      GPURenderPipelineDescriptor(
        vertex: GPUVertexState(
          module: device.createShaderModule(
            GPUShaderModuleDescriptor(
              code: triangleVertWGSL,
            ),
          ),
          entryPoint: 'main',
        ),
        fragment: GPUFragmentState(
          module: device.createShaderModule(
            GPUShaderModuleDescriptor(
              code: redFragWGSL,
            ),
          ),
          entryPoint: 'main',
          targets: [GPUColorTargetState(format: format)],
        ),
        primitive: GPUPrimitiveState(
          topology: 'triangle-list',
        ),
      ),
    );

    late void Function(num) frame;
    frame = (num f) {
      final GPUCommandEncoder cmdEncoder = device.createCommandEncoder();
      final GPUTextureView textureView = ctx.getCurrentTexture().createView();

      final GPURenderPassEncoder passEncoder = cmdEncoder.beginRenderPass(GPURenderPassDescriptor(
        colorAttachments: [
          GPURenderPassColorAttachment(
            view: textureView,
            loadValue: GPUColor(r: 0.0, g: 0.0, b: 0.0, a: 1.0),
            storeOp: 'store',
          ),
        ],
      ));
      passEncoder.setPipeline(pipeline);
      passEncoder.draw(3, 1, 0, 0);
      passEncoder.endPass();

      device.queue.submit([cmdEncoder.finish()]);
      window.requestAnimationFrame(frame);
    };

    window.requestAnimationFrame(frame);
  }
}


const triangleVertWGSL = '''
[[stage(vertex)]]
fn main([[builtin(vertex_index)]] VertexIndex : u32)
     -> [[builtin(position)]] vec4<f32> {
  var pos = array<vec2<f32>, 3>(
      vec2<f32>(0.0, 0.5),
      vec2<f32>(-0.5, -0.5),
      vec2<f32>(0.5, -0.5));

  return vec4<f32>(pos[VertexIndex], 0.0, 1.0);
}
''';

const redFragWGSL = '''
[[stage(fragment)]]
fn main() -> [[location(0)]] vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
''';
