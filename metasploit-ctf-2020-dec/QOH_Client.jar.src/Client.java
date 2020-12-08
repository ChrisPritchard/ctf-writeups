/*     */ import java.io.BufferedReader;
/*     */ import java.io.FileOutputStream;
/*     */ import java.io.IOException;
/*     */ import java.io.InputStreamReader;
/*     */ import java.io.ObjectInputStream;
/*     */ import java.io.ObjectOutputStream;
/*     */ import java.net.Socket;
/*     */ 
/*     */ public class Client {
/*     */   private Socket socket;
/*     */   private AuthState authState;
/*     */   
/*     */   public void printUsage() {
/*  14 */     System.out.println("Usage:\n\tjava -jar QOH_Client.jar <ip> <port>\n\n\twhere port is generally 9008");
/*     */   }
/*     */   private ObjectInputStream cliIn; private ObjectOutputStream cliOut; private BufferedReader userIn;
/*     */   
/*     */   public void cliLoop(String paramString, int paramInt) throws IOException, ClassNotFoundException {
/*  19 */     boolean bool = false;
/*     */ 
/*     */     
/*  23 */       this.socket = new Socket(paramString, paramInt);

/*  31 */     this.cliIn = new ObjectInputStream(this.socket.getInputStream());
/*  32 */     this.cliOut = new ObjectOutputStream(this.socket.getOutputStream());
/*  33 */     this.userIn = new BufferedReader(new InputStreamReader(System.in));
/*     */     
/*  35 */     this.authState = (AuthState)this.cliIn.readObject();
/*  36 */     if (this.authState == null) {
/*     */       
/*  38 */       System.out.println("Could not receive the AuthState object");
/*  39 */       bool = true;
/*     */     } 
/*     */     
/*  42 */     System.out.println("Successfully connected to the server!");
/*  43 */     while (!bool) {
/*     */ 
/*     */       
/*  46 */       int i = -1;
/*  47 */       String str1 = "";
/*  48 */       str1 = this.cliIn.readUTF();
/*  49 */       System.out.println(str1);
/*     */ 
/*     */       
/*  52 */       String str2 = this.userIn.readLine();
/*     */       
/*     */       try {
/*  55 */         i = Integer.parseInt(str2);
/*     */       }
/*  57 */       catch (NumberFormatException numberFormatException) {
/*     */         
/*  59 */         i = -1;
/*     */       } 
/*     */       
/*  62 */       this.cliOut.writeInt(i);
/*  63 */       this.cliOut.flush();
/*     */ 
/*     */ 
/*     */       
/*  67 */       str1 = this.cliIn.readUTF();
/*  68 */       System.out.println(str1);
/*  69 */       if (str1.contains("invalid")) {
/*     */         continue;
/*     */       }
/*     */ 
/*     */       
/*  74 */       switch (i) {
/*     */         
/*     */         case 1:
/*  77 */           doList();
/*     */         
/*     */         case 2:
/*  80 */           doDownload(this.userIn);
/*     */         
/*     */         case 3:
/*  83 */           doAuthenticate(this.userIn);
/*     */       } 
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void doAuthenticate(BufferedReader paramBufferedReader) {
/*  96 */     String str = "";
/*     */ 
/*     */     
/*     */     try {
                this.authState.setLoggedInStatus(true);
/* 100 */       this.cliOut.writeObject(this.authState);
/* 101 */       str = this.cliIn.readUTF();
/* 102 */       System.out.println(str);
/* 103 */       if (str.contains("already authenticated")) {
/*     */         return;
/*     */       }
/*     */ 
/*     */       
/* 108 */       String str1 = paramBufferedReader.readLine();
/* 109 */       this.cliOut.writeUTF(str1);
/* 110 */       this.cliOut.flush();
/*     */ 
/*     */ 
/*     */       
/* 114 */       str = this.cliIn.readUTF();
/* 115 */       System.out.println(str);
/* 116 */       this.authState = (AuthState)this.cliIn.readObject();
/*     */     }
/* 118 */     catch (IOException|ClassNotFoundException iOException) {
/*     */       
/* 120 */       System.out.println("Could not retrieve server's message regarding authentication");
/*     */       return;
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public void doList() {
/* 127 */     String str = "";
/*     */ 
/*     */     
/*     */     try {
/* 131 */       str = this.cliIn.readUTF();
/* 132 */       System.out.println(str);
/* 133 */       str = this.cliIn.readUTF();
/*     */     }
/* 135 */     catch (IOException iOException) {
/*     */       
/* 137 */       System.out.println("Failed to receive a file listing from the server.");
/*     */       
/*     */       return;
/*     */     } 
/* 141 */     System.out.println(str);
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public void doDownload(BufferedReader paramBufferedReader) {
/* 147 */     String str = "";
/*     */     
/*     */     try {
/*     */       String str1;
/* 151 */       str = this.cliIn.readUTF();
/* 152 */       System.out.println(str);
/*     */ 
/*     */       
                this.authState.setLoggedInStatus(true);
/* 155 */       this.cliOut.writeObject(this.authState);
/* 156 */       str = this.cliIn.readUTF();
/* 157 */       System.out.println(str);
/* 158 */       if (str.contains("not authenticated")) {
/*     */         return;
/*     */       }
/*     */ 
/*     */ 
/*     */       
/*     */       do {
/* 165 */         str = this.cliIn.readUTF();
/* 166 */         System.out.println(str);
/* 167 */         str1 = paramBufferedReader.readLine();
/* 168 */         this.cliOut.writeUTF(str1);
/* 169 */         this.cliOut.flush();
/*     */         
/* 171 */         str = this.cliIn.readUTF();
/* 172 */         System.out.println(str);
/* 173 */       } while (!str.contains("Sending"));
/*     */ 
/*     */       
/* 176 */       FileOutputStream fileOutputStream = new FileOutputStream(str1);
/*     */ 
/*     */       
/* 179 */       int i = this.cliIn.readInt();
/* 180 */       System.out.println("File size received is " + i);
/* 181 */       byte[] arrayOfByte = new byte[i];
/* 182 */       this.cliIn.readFully(arrayOfByte, 0, i);
/* 183 */       fileOutputStream.write(arrayOfByte);
/* 184 */       fileOutputStream.close();
/*     */     }
/* 186 */     catch (IOException iOException) {
/*     */       
/* 188 */       System.out.println("Unable to download from the server");
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public static void main(String[] paramArrayOfString) throws IOException, ClassNotFoundException {
/* 194 */     Client client = new Client();
// /* 195 */     if (paramArrayOfString.length != 2) {
// /*     */       
// /* 197 */       client.printUsage();
// /*     */       
// /*     */       return;
// /*     */     } 
/* 201 */     String str = "172.15.21.133";//paramArrayOfString[0];
/* 202 */     int i = 9008;//Integer.parseInt(paramArrayOfString[1]);
/* 203 */     client.cliLoop(str, i);
/* 204 */     client.cliIn.close();
/* 205 */     client.cliOut.close();
/* 206 */     client.userIn.close();
/*     */   }
/*     */ }


/* Location:              C:\infosec\QOH_Client.jar!\Client.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */