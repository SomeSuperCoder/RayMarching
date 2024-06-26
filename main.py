from moderngl import Context
import moderngl_window as mglw
from moderngl_window.timers.base import BaseTimer

class App(mglw.WindowConfig):
    window_size = 1600, 900
    resource_dir = "programs"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.quad = mglw.geometry.quad_fs()
        self.prog = self.load_program(vertex_shader="vertex_shader.glsl", fragment_shader="fragment_shader.glsl")
        self.set_uniform("u_resolution", self.window_size)


    def set_uniform(self, u_name, u_value):
        try:
            self.prog[u_name] = u_value
        except KeyError:
            print(f"{u_name} not used in shader")

    def render(self, time: float, frame_time: float):
        self.ctx.clear()
        self.set_uniform("u_time", time)
        self.quad.render(self.prog)

    def mouse_position_event(self, x: int, y: int, dx: int, dy: int):
        self.set_uniform("u_mouse", (x, y))

if __name__ == "__main__":
    mglw.run_window_config(App)
