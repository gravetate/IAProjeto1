import pygame
import threading
import time


def play_music():
    pygame.mixer.init()
    pygame.mixer.music.load('bombbbb.mp3')
    pygame.mixer.music.play(0)
    while pygame.mixer.music.get_busy():  
        time.sleep(1)  
    pygame.mixer.music.load('main-music.mp3')
    pygame.mixer.music.play(-1)



def stop_music():
    pygame.mixer.music.stop()


# Executa a música em segundo plano
thread = threading.Thread(target=play_music)
thread.start()