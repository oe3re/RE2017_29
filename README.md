# RE2017_29
Pravljenje stereo zvuka


Napraviti program koji od dva ulazna PCM fajla koji predstavljaju stereo zvuk jedne iste
melodije pravi izlazni fajl u WAV formatu. Odbirci stereo zvuka se zapisuju tako što se upisuju
redom odbirci za levi i desni zvučnik. Naime, upisuje se jedan odbirak signala za levi zvučnik,
a zatim jedan odbirak za desni zvučnik i tako dok se ne upišu svi odbirci.
Izlazni WAV fajl ima specijalno zaglavlje koje iznosi 44B, nakon čega slede odbirci signala.
Zaglavlje WAV falja je kao na linku: http://www.topherlee.com/software/pcm-tut-wavformat.
html. Obratiti pažnju da između 41-44 bajta u zaglavlju treba ispisati veličinu segmenta koji
čine odbirci signala u bajtovima. Odbirci se predstavljaju kao 16-bitni i prepisuju direktno kao
u PCM fajlu.

