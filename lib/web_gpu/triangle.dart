import 'dart:html';

import 'support.dart';


class Triangle {
  Triangle({
    required final this.ctx,
    required final this.device,
    required final this.format,
  });

  final GPUCanvasContext ctx;
  final GPUDevice device;
  final String format;

  void draw() {
    final GPURenderPipeline pipeline = device.createRenderPipeline(
      GPURenderPipelineDescriptor(
        vertex: GPUVertexState(
          module: device.createShaderModule(
            GPUShaderModuleDescriptor(
              code: vertWGSL,
            ),
          ),
          entryPoint: 'main',
        ),
        fragment: GPUFragmentState(
          module: device.createShaderModule(
            GPUShaderModuleDescriptor(
              code: fragWGSL,
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
    frame = (final num _) {
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
      passEncoder.draw(6, 1, 0, 0);
      passEncoder.endPass();

      device.queue.submit([cmdEncoder.finish()]);
      window.requestAnimationFrame(frame);
    };

    window.requestAnimationFrame(frame);
  }
}


const vertWGSL = '''
[[stage(vertex)]]
fn main([[builtin(vertex_index)]] idx : u32) -> [[builtin(position)]] vec4<f32> {
  var scale = 0.75;
  var pos = array<vec2<f32>, 6>(
    vec2<f32>( scale,  scale),
    vec2<f32>(-scale,  scale),
    vec2<f32>(-scale, -scale),
    vec2<f32>( scale,  scale),
    vec2<f32>(-scale, -scale),
    vec2<f32>( scale, -scale),
  );

  return vec4<f32>(pos[idx], 0.0, 1.0);
}
''';

const fragWGSL = '''
[[stage(fragment)]]
fn main() -> [[location(0)]] vec4<f32> {
  return vec4<f32>(1.0, 0.0, 1.0, 1.0);
}
''';
