`timescale 1 ns/1 ps

task automatic write_pcap_task
    (
     integer fd,
      reg       clk,
      reg       packet_en,
      reg [7:0] packet[64]
     );

    automatic reg [7:0]       file_hdr [23:0];
    automatic reg [7:0]       pcap_hdr [15:0]; 
    automatic reg [31:0]      len_pac;

    foreach(file_hdr[i]) $fwrite(fd,"%c",file_hdr[i]);
    
    @(posedge clk);
    while(1) begin
        @(posedge clk);
        if (packet_en) begin
            len_pac = packet.size();
            pcap_hdr[0] = len_pac[7:0];
            pcap_hdr[1] = len_pac[15:8];
            pcap_hdr[2] = len_pac[23:16];
            pcap_hdr[3] = len_pac[31:24];
            pcap_hdr[4] = len_pac[7:0];
            pcap_hdr[5] = len_pac[15:8];
            pcap_hdr[6] = len_pac[23:16];
            pcap_hdr[7] = len_pac[31:24];

            foreach(pcap_hdr[i]) $fwrite(fd,"%c",pcap_hdr[i]);
            foreach(packet[i]) $fwrite(fd,"%c",packet[i]);
        end
    end

endtask
