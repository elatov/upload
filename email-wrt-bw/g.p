set title "Sept 2015 (Incoming: 46222MB Outgoing: 11615MB)
set terminal png size 800,600 enhanced font "Helvetica,10"
set output 'output.png'
set grid
set style data histogram
set style histogram cluster gap 2
set style fill solid border -1
set boxwidth 1.1 
set xtic scale 0
set format y '%.2b%B'
#set xtics format '%s%c'
#set format y "%.0s%cB"\n
#plot "traf.dat" using 2:($1/1024**2) title "Incoming",""using 3:($1/1024**2) title "Outgoing"
plot "traf.dat" using 2:xtic(1) title "Incoming",""using 3:xtic(1) title "Outgoing"
