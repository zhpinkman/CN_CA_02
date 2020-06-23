
# http://www.mathcs.emory.edu/~cheung/Courses/558/Syllabus/04-NS/ns.html
# https://www.absingh.com/ns2/
# https://ns2blogger.blogspot.com/p/the-file-written-by-application-or-by.html


#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
set nf [open out.nam w]
set cwnd_outfile [open cwnd.out w]
set f [open trace.tr w]
$ns namtrace-all $nf


#Define a 'finish' procedure
proc finish {} {
    global ns nf cwnd_outfile f tcp0 tcp1


    set lastACK0 [$tcp0 set ack_]
    set lastSEQ0 [$tcp0 set maxseq_]
    puts stdout "final ack0: $lastACK0, final seq num0: $lastSEQ0"

    # since the bottleneck for both of the flows is 100 kbps that means (100 / 8) packet/s so 10000/8 = 1250 packets have been sent

    set lastACK1 [$tcp1 set ack_]
    set lastSEQ1 [$tcp1 set maxseq_]
    puts stdout "final ack1: $lastACK1, final seq num1: $lastSEQ1"

    
    $ns flush-trace
    #Close the NAM trace file
    close $nf
    close $cwnd_outfile
    close $f


    #Execute NAM on the trace file
    # exec nam out.nam &
    exit 0
}

# Random number between min and max including them
proc randomGenerator {min max} {
    return [expr {int(rand()*[expr $max - $min + 1] ) + $min}]
}

proc cwndPlotWindow {tcp0 tcp1 outfile} {
    global ns

    set now [$ns now]
    set cwnd0 [$tcp0 set cwnd_]
    set cwnd1 [$tcp1 set cwnd_]

#  Print TIME CWND   for  gnuplot to plot progressing on CWND   
    puts  $outfile  "$now $cwnd0 $cwnd1"
    

    $ns at [expr $now+0.1] "cwndPlotWindow $tcp0 $tcp1 $outfile"
}

# proc packetDropWindow {n2 n3 outfile} {
#     global ns

#     set now [$ns now]
#     set qq [$ns monitor-queue $n2 $n3 [open queue.tmp w] 0.05]
#     set bdrop [$qq set bdrops_]  

# #  Print TIME CWND   for  gnuplot to plot progressing on CWND  
#     puts  $outfile "$now $bdrop" 

#     $ns at [expr $now+0.1] "packetDropWindow $n2 $n3 $outfile"
# }


set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]



set randomDelay0 [randomGenerator 5 25]
set randomDelay1 [randomGenerator 5 25]
puts "1->2 variable delay: $randomDelay0"
puts "3->5 variable delay: $randomDelay1"
$ns duplex-link $n0 $n2 100Mb 5ms DropTail
$ns duplex-link $n1 $n2 100Mb [expr $randomDelay0]ms DropTail
$ns duplex-link $n2 $n3 0.1Mb 1ms DropTail
$ns duplex-link $n3 $n4 100Mb 5ms DropTail
$ns duplex-link $n3 $n5 100Mb [expr $randomDelay1]ms DropTail

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $n2 $n3 10
$ns queue-limit $n3 $n2 10




#Give node position (for NAM)
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n5 orient right-down


#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5

#Setup a TCP connection
set tcp0 [new Agent/TCP/Reno]
$tcp0 set fid_ 1
$tcp0 set packetSize_ 1000
$tcp0 set ttl_ 64
$ns attach-agent $n0 $tcp0

$tcp0 attach $f
$tcp0 tracevar cwnd_
# $tcp0 tracevar ssthresh_
$tcp0 tracevar ack_
# $tcp0 tracevar maxseq_

set tcp1 [new Agent/TCP/Reno]
$tcp1 set fid_ 2
$tcp1 set packetSize_ 1000
$tcp1 set ttl_ 64
$ns attach-agent $n1 $tcp1

set sink4 [new Agent/TCPSink]
$ns attach-agent $n4 $sink4

set sink5 [new Agent/TCPSink]
$ns attach-agent $n5 $sink5

$ns connect $tcp0 $sink4
$ns connect $tcp1 $sink5 


set cbr1 [new Application/Traffic/CBR]
$cbr1 attach-agent $tcp0
$cbr1 set type_ CBR
$cbr1 set rate_ 1mb


set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $tcp1
$cbr2 set type_ CBR
$cbr2 set rate_ 1mb


#Schedule events for the CBR agents
$ns at 0.0 "$cbr1 start"
$ns at 0.0 "$cbr2 start"
$ns at 1000.0 "$cbr1 stop"
$ns at 1000.0 "$cbr2 stop"

$ns  at  0.0  "cwndPlotWindow $tcp0 $tcp1 $cwnd_outfile" 
# $ns  at  0.0  "packetDropWindow $n2 $n3 $drop_outfile" 


#Call the finish procedure after 5 seconds of simulation time
$ns at 1000.0 "finish"

#Print CBR packet size and interval
# puts "CBR packet size = [$cbr set packet_size_]"
# puts "CBR interval = [$cbr set interval_]"

#Run the simulation
$ns run