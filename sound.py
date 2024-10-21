import pygame
import threading

def play_music():
    pygame.mixer.init()
    pygame.mixer.music.load('main-music.mp3')
    pygame.mixer.music.play(-1)

def stop_music():
    pygame.mixer.music.stop()

# Executa a música em segundo plano
thread = threading.Thread(target=play_music)
thread.start()