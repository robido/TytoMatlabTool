function serial_send_bytes( PORT, BYTES )
try
    fwrite(PORT,BYTES,'async');
catch e
    disp(e.message);
end
end

