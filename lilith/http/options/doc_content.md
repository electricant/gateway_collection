# A.K.A. Come diavolo funziona questo affare??

Questa pagina vuole essere una (spero) breve descrizione di come funziona
l'oggetto da cui proviene il presente testo.

Non si tratta di una guida per i neofiti, bensi di un posto in cui vado a
tenere traccia delle scelte di progetto. Questa pagina è infatti l'ultima cosa
che scrivo e comincio a ritenere il software completo.
Dal momento che con ogni probabilità non ci metterò più mano ritengo sia cosa
buona e giusta descrivere da qualche parte come è organizzato il software che
anima questo PC.

Non si sa mai che torni utile in futuro a me, quando mi sarò dimenticato che
cosa ho fatto, oppure a qualcuno (mi auguro) che voglia estendere e mantenere
quest'opera. Consideratelo il mio testamento se vi fa stare bene pensare ciò.

Dunque da dove cominciare? Credo che come tutte le cose sia bene cominciare da
una visione di insieme. Dopodichè si descrivere come si sono raggiunti gli
obbiettivi partendo dal livello più basso per poi procedere per livelli di
astrazione successivi.

## Il software installato

Il sistema operativo installato è [Arch Linux](https://www.archlinux.org/).
Questa distribuzione è stata scelta per l'ampia disponibilità di pacchetti
sempre aggiornati e perchè parte del software qui utilizzato (`delegated`) è
disponibile sotto forma di pacchetto.

Perchè ho scelto GNU/Linux come sistema operativo (sono un po' *biased* su
questo ma cercherò di essere più oggettivo possibile):

* Flessibilità e semplicità di installazione e aggiornamento

* Gira su ogni oggetto (anche le pietre)

* Ha un sacco di pacchetti utili in ambito *networking*

* E' leggero e veloce. Nessun ambiente *desktop* è installato di *default* che
  a noi non serve e consuma solo potenza di calcolo

* Quello so usare bene

Perchè non avrei dovuto sceglierlo:

* Non lo sa usare nessuno (il che è un peccato)

I pacchetti che ho installato per realizzare le funzionalità desiderate sono:

* `isc-dhcp` il server DHCP ufficiale
  dell'[Internet Service Consortium](https://www.isc.org/downloads/dhcp).
  Semplice da configurare e leggero. Fa una cosa sola e la fa bene.

* `squid` proxy HTTP per eccellenza. Fa un po'di *caching* ma soprattutto
  intercetta le richieste dirette ai domini da sbloccare e le instrada verso
  `delegated`. I domini sbolccati si trovano nel file di configurazione
  `/etc/squid/unlock_domains.conf`.   
  Squid fa anche uso di un programma di *URL rewrite* per intercettare la pagina
  ufficiale di autenticazione e mostrarne una propria
  (http://192.168.6.1/noauth).

* `lighttpd` server HTTP leggero e facile da configurare. Serve tutta
  l'interfaccia grafica.

* `minidlna` condivide i file multimediali sulla rete usando il protocollo
  [DLNA](https://it.wikipedia.org/wiki/Digital_Living_Network_Alliance)

* `samba` condivide i file multimediali sulla rete tramite il protocollo di
  condivisione di file e carelle di windows. Utile per avere accesso in
  scrittura alla cartella dei file multimediali.

Un altro componente fondamentale, ma non installato perchè presente di default,
è `iptables`: il firewall di Linux. Questo componente ha il ruolo di far sì che,
tramite il [NAT](https://it.wikipedia.org/wiki/Network_address_translation),
tutte le connessioni uscenti da questo dispositivo appaiano provenienti da un
unico indirizzo IP ingannando così il meccanismo di autenticazione della rete
ONAOSI. Per vedere come è configurato si consulti il file
`/usr/local/bin/connect.sh`.

Menzione di tutto rispetto la merita anche `ssh` che, oltre a permettere
l'accesso e il login su questo computer (nome utente: `root`, password:
`???`), crea un canale di connessione cifrata con il mio server
(http://ipol.gq). Questo canale è utilizzato per l'instradamento dei domini da
sbloccare. Così facendo i dati appaiono illeggibili al firewall dell'ONAOSI che
non sa cosa farci e nel dubbio li lascia passare.

## Fortia

Fortia (dal latino [atti eroici e coraggiosi](http://www.dizionario-latino.com/dizionario-latino-italiano.php?lemma=FORTIA100)) è il programma cardine di questa
applicazione. E' responsabile del *login* sui *firewall* della rete ed è in 
grado di riautenticarsi se la connessione cade.

Ho deciso di chiamarla fortia dalla contrazione di **forti**net e
**a**uthentication. I *firewall* in uso dall'ONAOSI sono infatti prodotti dalla
[Fortinet](http://it.fortinet.com/) e sono proprio loro i responsabili di tutte
le seccature (sì, anche il blocco dei siti) che con questo accrocchio ho più o
meno risolto.

Negli anni ho fatto vari tentativi per evitare di dovermi ricordare la password
della rete ONAOSI ed esser sicuro che tutti i miei disppositivi fossero sempre
connessi. Scrissi anche un'applicazione per Android (che per un periodo godette di relativa fama). Questa invece è scritta in perl e il suo funzionamento è
illustrato qui sotto.

Inizialmente prova l'autenticazione. Se ha successo entra in un *loop* infinito
in cui ogni 15 minuti controlla se l'utente è ancora autenticato. In caso di
risposta affermativa effettua il *refresh* della pagina *keepalive*, altrimenti
si riautentica.

Se l'autenticazione fallisce con un nome utente o una password errati allora il
programma esce con il codice -1 (errore). Se invece il computer risculta già
autenticato esce senza segnalare alcun errore.   

E' compito di `systemd` eseguire il programma ogni 2 minuti se termina con
successo. Altrimenti si ferma, segnalando la necessità di un intervento
correttivo.

Il file di configurazione che contiene il nome utente e la password in uso per
l'autenticazione si trova al percorso `/root/ONAOSI/user.pl`.

## L'interfaccia web

L'interfaccia web si articola in due componenti principali: il *backend* e il
*frontend*.

Il *backend* è responsabile dell'interazione a basso livello con il sitstema.
Gestisce i vari file di configurazione e presenta i dati sullo stato dei vari
servizi in forma gestibile da parte del frontend.

Il *frontend* è invece l'interfaccia grafica vera e propria, quella a cui si
accede con il browser econ cui l'utente interagisce.

Tutti i file relativi all'interfaccia sono situati nelle cartelle:

* `/srv/http/cgi` per gli script relativi al *backend*;

* `/srv/http/` per la pagina di stato e le risorse condivise tra tutte le altre
  pagine web;

* `/srv/http/options` per le pagine di configurazione.

### Backend

E' interamente gestito da alcuni script in perl e bash a cui si accede tramite
[CGI](https://it.wikipedia.org/wiki/Common_Gateway_Interface).
Ovvero il *frontend* accede ai dati effettuando delle richieste HTTP indirizzate
ad un determinato script a cui fornisce eventuali parametri ed elabora la
risposta ricevuta.

Gli script sono il più possibile minmali e con un singolo scopo ciascuno.
Questo semplifica il debug e rende tutta l'interfaccia più elegante. Segue una
lista di questi script con i relativi parametri e funzioni.

* `devctl.sh` Controlla il dispositivo. Parametri:
 * `reboot` riavvia il sistema
 * `shutdown` arresta il sistema

* `fortia.sh` Controlla lo stato e riavvia il servizio di autenticazione.
  Parametri:
 * `restart` riavvia il servizio
 * `status` restituisce `OK` se il servizio funziona correttamente `FAIL` se
    c'è un errore

* `get_logs.sh` Restituisce il log di varie funzionalità. Parametri:
 * `fortia` log relativi allo stato dell'autenticazione
 * `misc` log vari come memoria libera e utilizzo CPU
 * `proxy` stato del proxy che sblocca i domini
 * `timers` eventi ricorrenti

* `proxy.sh` Controlla lo stato e riavvia i servizi che rendono possibile lo
  sblocco dei domini (`squid`, `socks_proxy` e `delegated`). Parametri:
 * `restart` riavvia i servizi
 * `status` restituisce `OK` se tutto è in regola oppure `FAIL` se anche solo
   uno dei servizi risulta in errore

* `remote_help.sh` Servizio che attiva il *reverse proxy* per l'aiuto da remoto
  Parametri:
 * `start` avvia il servizio
 * `stop` ferma il servizio
 * `status` restituisce `RUNNING` se il servizio attivo e `STOPPED` se è fermo

* `serverapi.pl` Script chiave per l'interfaccia utente. E' responsabile della
  gestione dei file di configurazione. Scritto in perl anzichè bash per rendermi  la vita più semplice. Supporta esclusivamente il parametro `action` il cui
  valore specifica che cosa questo script debba fare. I valori ammessi sono:
 * `dhcp_clients` fornisce una tabella ben formattata delle *lease* DHCP in
   uso
 * `get_unlocked` fornisce una lista ben formattata dei domini che sono
   intercettati e passano attraverso il proxy ssh
 * `mkdom` aggiungi un dominio alla lista di quelli sbloccati. Vuole come
   parametro ausiliario `domain=valore` dove valore è il dominio da aggiungere
 * `rmdom` rimuovi un dominio dalla lista di quelli sbloccati. Vuole il
   parametro ausiliario `id` che rappresenta la riga corrispondente al dominio
   da rimuovere nel file di configurazione.
 * `get_username` restituisci il nome utente utilizzato per l'autenticazione
   sulla rete ONAOSI
 * `chgauth` cambia il nome utente e la password di autenticazione. Richiede
   come parametri: `user=nuovo_nome` e `pass=nuova_password`

Su un sistema linux o unix (ma anche windows con installato
[cygwin](https://www.cygwin.com/)) si può testare il backend tramite il comando
`curl`. Ad esempio si provi ad eseguire:

	curl http://192.168.6.1/cgi/get_logs.sh?misc

Nel momento in cui scrivo questa pagina l'*output* di tale comando è:

	22:08:28 up 11 days,  1:36,  1 user,  load average: 0.01, 0.03, 0.05

	       total       used        free      shared  buff/cache   available
	Mem:   1.5G        213M         78M        696K        1.2G        1.2G
	Swap:  1.9G         22M        1.9G

	Hard disk temperature: 44°C

Oppure si possono fornire parametri con un valore (occhio a non cambiare le
impostazioni. O meglio se le cambi ricordati quali erano quelle di prima). Ad
esempio:

	curl http://192.168.6.1/cgi/serverapi.pl?action=get_username

restituisce ora:
	
	scarampdm16

### Frontend

E' composto da una serie di pagine HTML che tramite JavaScript effettuano delle
richieste di tipo [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest). Queste richieste sono volte a completare i campi mancanti
sulle varie pagine e a modificarne il layout sulla base dello stato dei servizi,
così come è riportato dal backend.

La funzione cardine dell'implementazione è `fetchAndPut(what, putFunction)` (si
veda il sorgente di questa pagina, ad esempio premendo CTRL/CMD + U) che si
occupa di ottenere in maniera asincrona il contenuto di una pagina web e
chiamare la funzione `putFunction` quando i dati sono stati completamente
scaricati.

Sono state usate i seguenti componenti aggiuntivi:
* [Font Awesome](https://fortawesome.github.io/Font-Awesome) Per le icone dei
  menu e dei bottoni
* [marked](https://github.com/chjj/marked) Per il *parsing* del file
  [Markdown](https://it.wikipedia.org/wiki/Markdown) che contiene questo testo.

Si rimanda ai vari sorgenti nella cartella `/srv/http` per maggiori dettagli.
Tutto dovrebbe essere (mi auguro) ben commentato.
