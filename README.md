# rainy-day-reservations
A Swift iOS application to demonstrate the use of the CloudKit framework.

To work with the demo app you’ll need an active iOS developer account. Without one, you won’t be able to enable the iCloud entitlements or access the CloudKit dashboard.

With the project open, and your target selected ensure the the General applications panel is displayed. Next, you’ll want to configure the bundler identifier to use your own unique namespace.  Remember, iCloud container names are based off of your bundle identifier, and are global among all Apple developers, so this is a very important step.   Your can see here that bundle identifier is set to my own: com.groovytree.RainyDayReservations, and you’ll want to change to something unique to your own environment.  Once you've done that, you’ll most likely see an error appear for provisioning setup under the Team section here stating a matching provisioning profile wasn't  found .  To resolve this, you can simply select you own account from from the dropdown or press the “Fix Issue” button to have Xcode try and automatically resolve it. 

After you have the bundle identifier configured, you’ll next want to go over to the Capabilities tab of the project panel.  You'll see that the iCloud capability is listed 1st, and you’ll simply want to toggle it ON.   Next,  you'll want to ensure that the CloudKit service is enabled the Services section here, so that Xcode will add the required entitlements.  If everything works correctly, you see that the default container has automatically been created and enabled based on your apps bundler identifier.  

When you first run the App in the developement enviroment it will attempt to create all the Record Type schemas needed for the app using the just-in-time capability of CloudKit.

Good Luck!
