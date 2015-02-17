function rt_serial_send_bytes( PORT, BYTES )
    for m = 1:numel(BYTES)
        
        % sends it
        invoke(PORT, 'PutChar', BYTES(m))
    end
end

