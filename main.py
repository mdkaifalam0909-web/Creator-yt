import kivy
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.videoplayer import VideoPlayer

class Web3VideoApp(App):
    def build(self):
        self.layout = BoxLayout(orientation='vertical', padding=10, spacing=10)

        self.title_label = Label(
            text="[b]Web3 Video Streamer[/b]",
            markup=True,
            font_size='20sp',
            size_hint=(1, 0.1),
            color=(0, 0.8, 1, 1)
        )
        self.layout.add_widget(self.title_label)

        self.url_input = TextInput(
            hint_text="Paste Video / Stream URL...",
            multiline=False,
            size_hint=(1, 0.1)
        )
        self.layout.add_widget(self.url_input)

        self.play_button = Button(
            text="Play Video",
            size_hint=(1, 0.1),
            background_color=(0.2, 0.7, 0.3, 1)
        )
        self.play_button.bind(on_press=self.play_video_stream)
        self.layout.add_widget(self.play_button)

        self.player = VideoPlayer(
            source='',
            state='stop',
            options={'allow_stretch': True},
            size_hint=(1, 0.7)
        )
        self.layout.add_widget(self.player)

        return self.layout

    def play_video_stream(self, instance):
        stream_url = self.url_input.text.strip()
        if stream_url:
            self.player.source = stream_url
            self.player.state = 'play'

if __name__ == '__main__':
    Web3VideoApp().run()
  
