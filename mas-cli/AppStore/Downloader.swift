//
//  Downloader.swift
//  mas-cli
//
//  Created by Andrew Naylor on 21/08/2015.
//  Copyright (c) 2015 Andrew Naylor. All rights reserved.
//

func download(adamId: UInt64) -> MASError? {

    if let account = ISStoreAccount.primaryAccount {
        let group = dispatch_group_create()
        let purchase = SSPurchase(adamId: adamId, account: account)
        
        var purchaseError: MASError?
        
        purchase.perform { purchase, unused, error, response in
            if let error = error {
                purchaseError = MASError(code: .PurchaseError, sourceError: error)
                dispatch_group_leave(group)
                return
            }
            
            if let downloads = response.downloads as? [SSDownload] where count(downloads) > 0 {
                let observer = PurchaseDownloadObserver(purchase: purchase)
                
                observer.errorHandler = { error in
                    purchaseError = error
                    dispatch_group_leave(group)
                }
                
                observer.completionHandler = {
                    dispatch_group_leave(group)
                }
                
                CKDownloadQueue.sharedDownloadQueue().addObserver(observer)
            }
            else {
                println("No downloads")
                purchaseError = MASError(code: .NoDownloads)
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_enter(group)
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        return purchaseError
    }
    else {
        return MASError(code: .NotSignedIn)
    }
}
