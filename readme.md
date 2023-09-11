## Background
  
So, I was bored and started playing with ArcaOS. This little trip down memory lane led to installing the current Open Watcom v2 and trying to compile my old RexxUtil project after 15+ years. Go figure, I found some issues and started fixing things. As I was fixing, I decided to test each function. I was on `SysGetMessage` and, as a diversion from looking at the stem functions, I remembered I had done a mkmsgf clone. I made a couple test MSG files with the mkmsgf to use with `SysGetMessage` and realized they were not quite correct. 
  
Yep, down a rabbit hole. Well, I need to look at the real format of MSG files. I needed to decompile an MSG file to verify the format. In the end, there was mkmsgd. I can decompile an MSG and use the old IBM mkmsgf to recompile with most options. 
  
- [MKMSGF Usage](MKMSGF-Usage)  
- [Input Message File](Input-Message-File)   
- [Original MKMSGF Issues](Original-MKMSGF-Issues) 
- [What-Standard?](What-Standard%3F) 
- [The A, C, and I Options](The-A,-C,-and-I-Options) 
- [The Extended Structure](The-Extended-Structure) 
- [Country Info](Country-Info)    
  
**References:**  

[CPGuide - Message Management](http://www.edm2.com/index.php/CPGuide_-_Message_Management) 
