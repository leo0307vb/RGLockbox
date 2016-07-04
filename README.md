[![Build Status](https://travis-ci.org/rdignard08/RGLockbox.svg?branch=swift-master)](https://travis-ci.org/rdignard08/RGLockbox)
[![Coverage Status](https://codecov.io/github/rdignard08/RGLockbox/coverage.svg?branch=objc-master)](https://codecov.io/github/rdignard08/RGLockbox?branch=objc-master)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/rdignard08/RGLockbox)
[![Pod Version](https://img.shields.io/cocoapods/v/RGSwiftKeychain.svg)](https://cocoapods.org/pods/RGSwiftKeychain)
[![Pod Platform](http://img.shields.io/cocoapods/p/RGSwiftKeychain.svg?style=flat)](http://cocoadocs.org/docsets/RGLockbox/)
[![Pod License](http://img.shields.io/cocoapods/l/RGSwiftKeychain.svg?style=flat)](https://github.com/rdignard08/RGLockbox/blob/swift-master/LICENSE)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=rdignard08/rglockbox)](http://clayallsopp.github.io/readme-score?url=rdignard08/rglockbox)

RGSwiftKeychain
=======
`RGLockbox` is a simple to use interface with the standard keychain.  Using object-orientented approaches it is simple to pick a key and store any rudimentary value there.

The Objective-C version of this pod is named `RGLockbox` and is available on the branch [objc-master](https://github.com/rdignard08/RGLockbox/tree/objc-master).

Default supported types include:
- `NSData`
- `String`
- `NSDate`
- `Dictionary`
- `Array`
- `NSCoding`
  - `NSURL`
  - `NSValue` (including `NSNumber` and `NSDecimalNumber`)
  - `NSNull`

Note for safety Apple encourages developers to conform their objects to `NSSecureCoding` instead of `NSCoding` to prevent substitution attacks against your app.

***IMPORTANT*** : when your application will terminate you should run `dispatch_barrier_sync()` on `keychainQueue`.

Example
=======
```swift
let data = "abcd".dataUsingEncoding(NSUTF8StringEncoding)
RGLockbox.manager().setData(data, forKey: "myData")
```
Writing data is as simple as creating it and applying it to your keychain manager.  By default these managers are namespaced to your bundle's identifier.

```swift 
let data = RGLockbox.manager().dataForKey("myData")!
let string = String.init(data: data, encoding: NSUTF8StringEncoding)!
assert(string == "abcd")
```
Retrieving data is as simple as remembering your key assuming you use the same manager throughout.  Mixing and matching managers with different namespaces is possible, but more of an advanced use case.

In addition to the primitive interface supporting reading and writing raw `NSData` there is implicit support for a variety of types.
`NSDate`:
```swift
let date = NSDate.init()
RGLockbox.manager().setDate(date, forKey: "myDate")
let readDate = RGLockbox.manager().dateForKey("myDate")!
assert(Int(date.timeIntervalSince1970) == Int(readDate.timeIntervalSince1970))
```
`String`:
```swift
let string = "aString"
RGLockbox.manager().setString(string, forKey: "stringKey")
let readString = RGLockbox.manager().stringForKey("stringKey")!
assert(string == readString)
```
`Dictionary`:
```swift
let dictionary = [ "aKey" : "aValue" ]
RGLockbox.manager().setJSONObject(dictionary, forKey: "dictionaryKey")
let readDictionary = RGLockbox.manager().JSONObjectForKey("dictionaryKey")!
assert(dictionary == readDictionary)
```
`Array`:
```swift
let array = [ "aValue1", "aValue2" ]
RGLockbox.manager().setJSONObject(array, forKey: "arrayKey")
let readArray = RGLockbox.manager().JSONObjectForKey("arrayKey")!
assert(array == readArray)
```
`NSCoding`:
```swift
let url = NSURL.init(string: "google.com")
RGLockbox.manager().setCodeable(url, forKey: "urlKey")
let readURL = RGLockbox.manager().codeableForKey("urlKey")!
assert(url == readURL)
```

Finally, this library supports arbitrary namespacing which allows sharing keychain data across app bundles as well as setting different item accessibility for advanced use cases.
```swift
let signupDate = NSDate.init(timeIntervalSince1970: 1453075980.0)
let lockbox = RGLockbox.init(withNamespace: "com.rglockbox.appbundle", accessibility: kSecAttrAccessibleAlways)
lockbox.setDate(signupDate, forKey: "userSignupDate")

/* In another program, app extension, component framework, etc. ... */

let lockbox = RGLockbox.init(withNamespace: "com.rglockbox.appbundle", accessibility: kSecAttrAccessibleAlways)
let signupDate = lockbox.dateForKey("userSignupDate")!
assert(signupDate.timeIntervalSince1970 == 1453075980.0)
```

Installation
=======
Using cocoapods add `pod 'RGSwiftKeychain'` to your Podfile and run `pod install`

License
=======
BSD Simplied (2-clause)
