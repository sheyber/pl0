var n, f, out;
begin
   n := 0;
   f := 1;
   while n # 16 do
   begin
      n := n + 1;
      f := f * n;
   end;
   out := f;
   call print;
end.