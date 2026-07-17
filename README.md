# Proiect_2-FPGA
 UART Loopback (TX + RX)
# Etapa 1 — UART Loopback (TX + RX) 
În această etapă implementați și verificați modulele UART de bază. Scopul este să demonstrați că tot ce trimiteți 
din PuTTY vă vine înapoi corect pe același terminal (loopback hardware): 
PuTTY → recepție UART → (fără procesare) → transmisie UART → PuTTY.

Implementarea primei etape a proiectului urmărește realizarea unei comunicații UART complete, formată din două componente principale: un modul de recepție (UART Receiver) și un modul de transmisie (UART Transmitter). Între cele două module este utilizat un generator de baud rate, care asigură sincronizarea procesului de recepție și transmisie prin generarea unui semnal periodic (tick).

Un cadru UART implementat în proiect este alcătuit din:
- 1 bit de start, utilizat pentru a semnala începutul transmisiei
- 8 biți de date, transmiși în ordinea LSB First
- 1 bit de stop, care marchează sfârșitul cadrului și readuce linia serială în starea de repaus

# Modulul baudrate_generator

Acest modul are rolul de a genera semnalul de sincronizare necesar comunicației UART. Deoarece comunicația serială se realizează la o viteză mult mai mică decât frecvența de funcționare a plăcii FPGA, este necesară divizarea frecvenței ceasului sistemului.
În cadrul implementării s-a presupus utilizarea unui ceas de 100 MHz, specific plăcii Nexys A7, și o viteză de comunicație de 9600 baud. Pentru a obține această rată de transmisie, modulul utilizează un contor care numără ciclurile de ceas. După atingerea valorii corespunzătoare unei perioade de bit (aproximativ 10417 cicluri), contorul este resetat și se generează un impuls (tick) cu durata unui singur ciclu de ceas.

# Modulul receiver

Modulul receiver implementează partea de recepție a protocolului UART utilizând o mașină de stări finite.
Scopul acestui modul este de a transforma fluxul serial primit pe linia RX într-un octet de date disponibil în paralel la ieșirea modulului.
Implementarea este împărțită în patru stări principale.

IDLE:

- este starea de repaus a receptorului; în această stare linia UART trebuie să fie în nivel logic HIGH, conform protocolului UART
- dacă linia rămâne la nivel logic 1, receptorul continuă să aștepte.
- în momentul în care detectează o tranziție la nivel logic LOW, aceasta este interpretată ca posibil început al unui nou cadru UART, iar automatul trece în starea START

START:
- scopul acestei stări este validarea bitului de start
- pentru a evita interpretarea unor impulsuri scurte sau a zgomotului drept început de transmisie, receptorul nu începe imediat citirea datelor; se utilizează un contor care măsoară aproximativ jumătate din durata unui bit
- după această perioadă, se verifică din nou valoarea semnalului RX:
	- dacă linia este încă LOW, se consideră că bitul de start este valid și recepția poate continua
	- dacă linia a revenit la HIGH, impulsul este considerat invalid, iar automatul revine în starea IDLE

DATA:
- în această stare are loc recepția efectivă a informației
- după fiecare impuls tick, receptorul citește valoarea prezentă pe linia RX
- bitul citit este memorat într-un registru intern (data_reg) pe poziția indicată de variabila bit_index
- protocolul UART transmite biții în ordinea LSB First, motiv pentru care indexul începe de la 0 și este incrementat după fiecare bit recepționat
- procesul continuă până când au fost recepționați toți cei opt biți ai caracterului
- la finalul recepției ultimului bit, automatul trece în starea STOP

STOP:
- ultima stare verifică existența bitului de stop
- conform protocolului UART, după cei opt biți de date trebuie să urmeze un bit cu valoarea logică HIGH
- la următorul impuls tick, receptorul verifică valoarea semnalului RX:
	- dacă aceasta este 1, octetul este considerat valid și este copiat pe ieșirea dataout
	- dacă valoarea este 0, este semnalată o eroare, deoarece cadrul UART nu respectă formatul standard
- după această verificare, automatul revine în starea IDLE, fiind pregătit pentru recepția unui nou caracter

# Modulul transmitter

Modulul transmitter are rolul de a transforma un octet de date primit în paralel într-un flux serial transmis pe linia TX. Implementarea este realizată sub forma unei mașini de stări finite, sincronizată cu semnalul tick generat de modulul baudrate_generator.
Ca și receptorul, emițătorul este organizat în patru stări principale, fiecare corespunzând unei etape din cadrul UART.

IDLE:
- reprezintă starea de repaus a emițătorului
- în această stare linia serială TX este menținută permanent la nivel logic HIGH, conform protocolului UART, iar semnalul tx_done este dezactivat
- Modulul monitorizează semnalul data_valid; atunci când acesta devine activ, octetul disponibil pe intrarea datain este copiat într-un registru intern (data_reg), indexul utilizat pentru transmiterea biților este resetat, iar automatul trece în starea START

START:
- în această stare este transmis bitul de start al cadrului UART
- linia TX este forțată la nivel logic LOW pentru durata unui bit; menținerea acestei valori este controlată de semnalul tick, astfel încât durata bitului de start să fie egală cu perioada unui bit UART
- după apariția următorului impuls tick, transmisia continuă cu primul bit de date

DATA:
- această stare realizează transmiterea efectivă a informației
- octetul memorat în registrul intern este transmis serial, câte un bit la fiecare impuls tick
- procesul continuă până când sunt transmiși toți cei opt biți ai caracterului
- după transmiterea ultimului bit, automatul trece în starea STOP

STOP:
- ultima stare transmite bitul de stop
- bitul de stop are întotdeauna valoarea logică HIGH, motiv pentru care ieșirea TX este readusă la nivel logic 1 pentru încă o perioadă de bit
- la apariția următorului impuls tick, transmisia este considerată finalizată; modulul activează semnalul tx_done, care poate fi utilizat pentru a semnala încheierea transmisiei, după care automatul revine în starea IDLE, pregătit pentru retransmiterea unui nou caracter

# Modulul tb_receiver
Pentru verificarea funcționării modulului UART Receiver a fost realizat un testbench dedicat, al cărui scop este simularea condițiilor reale de funcționare ale unei comunicații UART și validarea comportamentului mașinii de stări implementate.
Testbench-ul generează semnalul de ceas (clk), semnalul de reset (rst), impulsurile de sincronizare (tick) și semnalul serial de intrare (rx_serial). Scopul acestuia este de a reproduce structura unui cadru UART și de a verifica dacă receptorul parcurge corect toate stările mașinii de stări finite și reconstruiește octetul transmis.
Pentru simulare a fost ales caracterul 0xA5; testbench-ul construiește manual cadrul UART respectând structura protocolului:
- linia serială este menținută inițial în starea de repaus (nivel logic HIGH)
- este transmis bitul de start (LOW)
- urmează cei opt biți ai caracterului, trimiși în ordinea LSB First
- cadrul este încheiat prin transmiterea bitului de stop (HIGH)
Durata fiecărui bit este stabilită prin întârzieri calculate astfel încât să corespundă perioadei unui bit la 9600 baud, iar semnalul tick este generat periodic pentru a sincroniza eșantionarea biților de către receptor.

În stadiul actual al implementării, simularea nu reproduce încă în totalitate comportamentul așteptat. Acest lucru este cauzat, cel mai probabil, de durata insuficientă a simulării și de necesitatea ajustării sincronizării dintre semnalul tick și modificările aplicate semnalului rx_serial.
