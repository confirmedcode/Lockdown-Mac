//
//  EmailLoginView.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/6/19.
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import SwiftUI
import AppKit
import PromiseKit
import CocoaLumberjackSwift

struct EmailLoginView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var successCallback: () -> Void
    init(successCallback: @escaping () -> Void) {
        self.successCallback = successCallback
    }
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var isLoading: Bool = false
    
    @State private var errorText: String = ""
    
    var body: some View {
        
        VStack(spacing: 0.0) {
            
            Text("Login To Lockdown")
                .font(cFontTitle)
                .padding(.vertical, 10)
            Text("Create an account using Lockdown on your iPhone/iPad to enable Secure Tunnel. Open Lockdown on your iPhone/iPad and tap \"Account\" at the bottom right, then \"Sign Up\".")
                .font(cFontRegularSmall)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .multilineTextAlignment(.center)
            
            Text(errorText)
                .font(cFontSmall)
                .lineLimit(nil)
                .frame(minWidth: 0, maxWidth: 300, minHeight: errorText == "" ? 0 : 30)
                .foregroundColor(Color.flatRed)
                .padding(.bottom, 10)
                .padding(.horizontal, 10)
                .minimumScaleFactor(0.5)
                .opacity(errorText == "" ? 0 : 1)
        
            HStack {
                Text("Email")
                    .font(cFontSmall)
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .trailing)
                TextField("jane@example.com", text: $email)
                    .lineLimit(1)
                    .font(cFontRegular)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            HStack {
                Text("Password")
                    .font(cFontSmall)
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .trailing)
                SecureField("**********", text: $password, onCommit: {
                        //self.setCredentials()
                    })
                    .lineLimit(1)
                    .font(cFontRegular)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            
            HStack(spacing: 0) {
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                    .font(cFontSubtitle)
                        .foregroundColor(Color.white)
                    .frame(width: 80, height: 30)
                }
                .buttonStyle(GrayButtonStyle())
                .cornerRadius(8)
                .padding(8)
                
                Button(action: {
                    self.setCredentials()
                }) {
                    Text("Log In")
                    .font(cFontSubtitle)
                    .frame(width: 80, height: 30)
                }
                .buttonStyle(BlueButtonStyle())
                .disabled(isLoading)
                .cornerRadius(8)
                .padding(8)
            }
        }
        .frame(width: 300, height: 290)
        .padding(10)
    }
    
    func setCredentials() {
        if (email.isEmpty) {
            self.errorText = "Email cannot be blank."
            return
        }
        else if (password.isEmpty) {
            self.errorText = "Password cannot be blank."
            return
        }
        
        do {
            try setAPICredentials(email: self.email, password: self.password)
        }
        catch {
            self.errorText = "Error setting credentials: \(error)"
            return
        }
        
        isLoading = true
        
        firstly {
            try Client.signInWithEmail()
        }
        .done { (signin: SignIn) in
            isLoading = false
            self.presentationMode.wrappedValue.dismiss()
            self.successCallback()
        }
        .catch { error in
            isLoading = false
            clearAPICredentials()
            if (error as NSError).domain == NSURLErrorDomain {
                DDLogError("Login-error - Network Error. Please check your connection. Code \((error as NSError).code)")
                self.errorText = "Network Error. Please check your connection. Code \((error as NSError).code)"
            }
            else if let apiError = error as? ApiError {
                DDLogError("Login-error - API Error code \(apiError.code), message \(apiError.message).")
                switch (apiError.code) {
                    case kApiCodeIncorrectLogin:
                        self.errorText = "Incorrect Login."
                    case kApiCodeEmailNotConfirmed:
                        self.errorText = "Email is not confirmed. Check your email and click to confirm your email address."
                    case kApiCodeTooManyRequests:
                        self.errorText = "You've made too many requests in a short time period. Try again later."
                    default:
                        self.errorText = "Unexpected server error: \(apiError.message) (code \(apiError.code))"
                }
            }
            else {
                DDLogError("Login-error - Unexpected error: \(error.localizedDescription)")
                self.errorText = "Unexpected error: \(error.localizedDescription)"
            }
        }
    }
    
}

#if DEBUG
struct EmailLoginView_Preview: PreviewProvider {
    static var previews: some View {
        EmailLoginView(successCallback: {
            DDLogInfo("success callback called")
        })
    }
}
#endif

