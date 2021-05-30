"
Class:

I'm a trait that writes to disk the context in which an error has been detected, so it can be easily inspected and debugged offline. Not all errors are affected. Error strategies use this trait.

Responsibility:

When this trait is used in a class, the class can save to disk the error context.

Collaborators:

It delegates error handling to error strategy implementations.
It uses EDATLogging and EDASourceCodeHelperStub.

Public API and Key Messages:

- manageError:forCommand:usingErrorStrategy: When a command-related error is captured, it delegates the error handling to the error strategy.
- manageError:forMessage:usingErrorStrategy: When an arbitrary message cannot be processed, it delegates the error handling to the error strategy.
- manageError:whenProjectingEvent:usingErrorStrategy:: When a projection-related error is captured, it delegates the error handling to the error strategy.
"
Trait {
	#name : #EDACTErrorHelper,
	#traits : 'EDACTLogging',
	#classTraits : 'EDACTLogging classTrait',
	#category : #'EDAC-Traits'
}

{ #category : #helpers }
EDACTErrorHelper classSide >> basename [
	^ Time now yyyyMMddhhmmss24
]

{ #category : #helpers }
EDACTErrorHelper classSide >> errorFolderFor: basename [
	| parent result |
	parent := FileSystem workingDirectory / 'errors'.
	parent createDirectory.
	result := parent / basename greaseString.
	result createDirectory.
	^ result
]

{ #category : #logging }
EDACTErrorHelper classSide >> logDebugMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings debugEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'DEBUG'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACTErrorHelper classSide >> logErrorMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings errorEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'ERROR'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACTErrorHelper classSide >> logInfoMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings infoEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'INFO '
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACTErrorHelper classSide >> logTraceMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings traceEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'TRACE'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACTErrorHelper classSide >> logWarningMessage: aMessage beautify: aBoolean [
	^ EDACLoggingSettings warningEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'WARN '
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #handling }
EDACTErrorHelper >> manageError: anException forCommand: aCommand usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	errorHandler := (self class environment at: aStrategy asSymbol) new.
	errorHandler class shouldPersistFuel
		ifTrue: [ self
				logErrorMessage:
					'Error processing ' , aCommand greaseString , ': '
						, anException description greaseString.
			context := thisContext clone.
			basename := self class basename.
			self
				writeFuelContext: context
				named: anException class greaseString
				withBasename: basename.
			self writeCommand: aCommand withBasename: basename ].
	errorHandler context: context.
	dictionary := Dictionary new.
	dictionary at: #command put: aCommand.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: dictionary.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> manageError: anException forMessage: aString usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	self
		logErrorMessage:
			'Error processing ' , aString greaseString , ': '
				, anException description greaseString.
	dictionary := Dictionary new.
	dictionary at: #message put: aString.
	context := thisContext clone.
	basename := self class basename.
	self
		writeFuelContext: context
		named: anException class greaseString withBasename: basename.
	self writeMessage: aString withBasename: basename.
	errorHandler := (self class environment at: aStrategy asSymbol) new
		context: context.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: dictionary.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> manageError: anException usingErrorStrategy: aStrategy [
	| errorHandler result context basename |
	self
		logErrorMessage: 'Error detected: ' , anException description greaseString.
	basename := DateAndTime now asYYYYmmddHMS.
	context := thisContext clone.
	self
		writeFuelContext: context
		named: anException class greaseString
		withBasename: basename.
	errorHandler := (self class environment at: aStrategy asSymbol) new
		context: context.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: Dictionary new.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> manageError: anException whenProjectingEvent: anEvent usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	self
		logErrorMessage:
			'Error projecting ' , anEvent greaseString , ': '
				, anException description greaseString.
	context := thisContext clone.
	basename := self class basename.
	self
		writeFuelContext: context
		named:
			anException class greaseString , '-' , anEvent class greaseString
				, '.txt'
		withBasename: basename.
	self writeEvent: anEvent greaseString withBasename: basename.
	errorHandler := (self class environment at: aStrategy asSymbol) new
		context: context.
	dictionary := Dictionary new.
	dictionary at: #event put: anEvent.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: dictionary.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> writeCommand: aCommand withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename)
		/ (aCommand class printString , '.txt').
	result writeStream
		nextPutAll: aCommand printString;
		close.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> writeEvent: aString withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename) / 'event.txt'.
	result writeStream
		nextPutAll: aString;
		close.
	^ result
]

{ #category : #handling }
EDACTErrorHelper >> writeFuelContext: aContext named: aString withBasename: aBasename [
	| parentFolder |
	parentFolder := self class errorFolderFor: aBasename.
	^ EDAFuelHelper new
		writeFuelContext: aContext
		named: 'session.fuel'
		inFolder: parentFolder
]

{ #category : #handling }
EDACTErrorHelper >> writeMessage: aString withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename) / 'message.txt'.
	result writeStream
		nextPutAll: aString;
		close.
	^ result
]