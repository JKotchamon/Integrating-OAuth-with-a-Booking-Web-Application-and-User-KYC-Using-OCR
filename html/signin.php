<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');

if(isset($_POST['login'])) 
  {
    $email=$_POST['email'];
    $password=md5($_POST['password']);
    $sql ="SELECT ID FROM tbluser WHERE Email=:email and Password=:password";
    $query=$dbh->prepare($sql);
    $query->bindParam(':email',$email,PDO::PARAM_STR);
$query-> bindParam(':password', $password, PDO::PARAM_STR);
    $query-> execute();
    $results=$query->fetchAll(PDO::FETCH_OBJ);
    if($query->rowCount() > 0)
{
foreach ($results as $result) {
$_SESSION['hbmsuid']=$result->ID;
}
$_SESSION['login']=$_POST['email'];
echo "<script type='text/javascript'> document.location ='index.php'; </script>";
} else{
echo "<script>alert('Invalid Details');</script>";
}
}

?>
<!DOCTYPE HTML>
<html>
<head>
<title>Hotel Booking Management System | Hotel :: Login Page</title>
<link href="css/bootstrap.css" rel="stylesheet" type="text/css" media="all">
<link href="css/style.css" rel="stylesheet" type="text/css" media="all" />

<script type="application/x-javascript"> addEventListener("load", function() { setTimeout(hideURLbar, 0); }, false); function hideURLbar(){ window.scrollTo(0,1); } </script>
<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/bootstrap.js"></script>
<script src="js/responsiveslides.min.js"></script>
 <script>
    $(function () {
      $("#slider").responsiveSlides({
      	auto: true,
      	nav: true,
      	speed: 500,
        namespace: "callbacks",
        pager: true,
      });
    });
  </script>

</head>
<body>
		<!--header-->
			<div class="header head-top">
				<div class="container">
			<?php include_once('includes/header.php');?>
		</div>
</div>
<!--header-->
		<!--about-->
		
			<div class="content">
				<div class="contact">
				<div class="container">
					
					<h2>If you have an account with us, please log in.</h2>
					
				<div class="contact-grids">
					
						<div class="col-md-6 contact-right">
							<form method="post">

								<h5>Email Address</h5>
								<input type="email" class="form-control" value="" name="email" required="true">
								<h5>Password</h5>
								<input type="password" value="" class="form-control" name="password" required="true">
								<br />
								<a href="forgot-password.php">Forgot your password?</a>
								<br/>
								 <input type="submit" value="Login" name="login">
						 	 </form>

						 	 <br/>
						 	 <div style="text-align:center; margin-top:15px;">
						 	 	<p style="color:#777; margin-bottom:12px;">— or log in with —</p>

						 	 	<!-- Google Button -->
						 	 	<a href="google-callback.php" style="display:inline-flex; align-items:center; background:#4285F4; color:#fff; padding:0 16px 0 0; border-radius:4px; text-decoration:none; font-size:14px; font-weight:500; margin-bottom:10px; width:240px; height:42px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">
						 	 		<span style="background:#fff; border-radius:3px 0 0 3px; padding:10px 10px; margin-right:12px; display:flex; align-items:center;">
						 	 			<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.08 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-3.59-13.46-8.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/><path fill="none" d="M0 0h48v48H0z"/></svg>
						 	 		</span>
						 	 		Sign in with Google
						 	 	</a>
						 	 	<br/>

						 	 	<!-- Microsoft Button -->
						 	 	<a href="oauth-callback.php" style="display:inline-flex; align-items:center; background:#fff; color:#5E5E5E; padding:0 16px 0 0; border-radius:4px; text-decoration:none; font-size:14px; font-weight:500; width:240px; height:42px; border:1px solid #8C8C8C; box-shadow:0 2px 4px rgba(0,0,0,0.1);">
						 	 		<span style="padding:10px 10px; margin-right:12px; display:flex; align-items:center;">
						 	 			<svg width="18" height="18" viewBox="0 0 21 21"><rect x="1" y="1" width="9" height="9" fill="#F25022"/><rect x="11" y="1" width="9" height="9" fill="#7FBA00"/><rect x="1" y="11" width="9" height="9" fill="#00A4EF"/><rect x="11" y="11" width="9" height="9" fill="#FFB900"/></svg>
						 	 		</span>
						 	 		Sign in with Microsoft
						 	 	</a>
						 	 </div>

						</div>
						<div class="clearfix"></div>
					</div>
				</div>
			</div>
		<?php include_once('includes/getintouch.php');?>
			</div>
			<?php include_once('includes/footer.php');?>
</html>
