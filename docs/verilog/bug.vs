function int f (int arg);

  begin // comment to remove bug
  
    int i;
    f = 0;
    for (i=0; i<arg; i++)
      f += i;
      
  end	 // comment to remove bug

endfunction


module bug;

int sum;

assign sum = f(10);

endmodule
