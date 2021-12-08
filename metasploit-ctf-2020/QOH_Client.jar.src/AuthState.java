/*    */ import java.io.Serializable;
/*    */ 
/*    */ 
/*    */ 
/*    */ public class AuthState
/*    */   implements Serializable
/*    */ {
/*    */   private static final long serialVersionUID = 123197894L;
/*    */   private boolean loggedIn = false;
/* 10 */   private String username = "Guest";
/*    */ 
/*    */ 
/*    */   
/*    */   public boolean isLoggedIn() {
/* 15 */     return this.loggedIn;
/*    */   }
/*    */ 
/*    */   
/*    */   public void setLoggedInStatus(boolean paramBoolean) {
/* 20 */     this.loggedIn = paramBoolean;
/*    */   }
/*    */ }


/* Location:              C:\infosec\QOH_Client.jar!\AuthState.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */