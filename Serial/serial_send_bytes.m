function serial_send_bytes( PORT, BYTES )
    fwrite(PORT,BYTES,'async');
end

