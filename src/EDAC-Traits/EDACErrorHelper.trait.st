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
	#name : #EDACErrorHelper,
	#category : #'EDAC-Traits'
}

{ #category : #helpers }
EDACErrorHelper classSide >> basename [
	^ Time now yyyyMMddhhmmss24
]

{ #category : #helpers }
EDACErrorHelper classSide >> errorFolderFor: basename [
	| parent result |
	parent := FileSystem workingDirectory / 'errors'.
	parent createDirectory.
	result := parent / basename greaseString.
	result createDirectory.
	^ result
]

{ #category : #logging }
EDACErrorHelper classSide >> logDebugMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings debugEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'DEBUG'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACErrorHelper classSide >> logErrorMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings errorEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'ERROR'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACErrorHelper classSide >> logInfoMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings infoEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'INFO '
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACErrorHelper classSide >> logTraceMessage: aMessage beautify: aBoolean [
	EDACLoggingSettings traceEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'TRACE'
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #logging }
EDACErrorHelper classSide >> logWarningMessage: aMessage beautify: aBoolean [
	^ EDACLoggingSettings warningEnabled
		ifTrue: [ self
				logMessage: aMessage
				inCategory: 'WARN '
				inStream: self defaultStream
				beautify: aBoolean ]
]

{ #category : #handling }
EDACErrorHelper >> logErrorMessage: aString [
	^ EDACLoggingStub new logErrorMessage: aString
]

{ #category : #handling }
EDACErrorHelper >> manageError: anException forCommand: aCommand usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	errorHandler := (self class environment at: aStrategy asSymbol) new.
	errorHandler class shouldPersistFuel
		ifTrue: [ self
				logErrorMessage:
					'Error processing ' , aCommand printString , ': '
						, anException description printString.
			context := thisContext clone.
			basename := self class basename.
			self
				writeFuelContext: context
				named: anException class printString
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
EDACErrorHelper >> manageError: anException forMessage: aString usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	self
		logErrorMessage:
			'Error processing ' , aString printString , ': '
				, anException description printString.
	dictionary := Dictionary new.
	dictionary at: #message put: aString.
	context := thisContext clone.
	basename := self class basename.
	self
		writeFuelContext: context
		named: anException class printString withBasename: basename.
	self writeMessage: aString withBasename: basename.
	errorHandler := (self class environment at: aStrategy asSymbol) new
		context: context.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: dictionary.
	^ result
]

{ #category : #handling }
EDACErrorHelper >> manageError: anException usingErrorStrategy: aStrategy [
	| errorHandler result context basename |
	self
		logErrorMessage: 'Error detected: ' , anException description printString.
	basename := DateAndTime now asYYYYmmddHMS.
	context := thisContext clone.
	self
		writeFuelContext: context
		named: anException class printString
		withBasename: basename.
	errorHandler := (self class environment at: aStrategy asSymbol) new
		context: context.
	result := errorHandler
		handleError: anException
		withExtraContextInformation: Dictionary new.
	^ result
]

{ #category : #handling }
EDACErrorHelper >> manageError: anException whenProjectingEvent: anEvent usingErrorStrategy: aStrategy [
	| errorHandler result context basename dictionary |
	self
		logErrorMessage:
			'Error projecting ' , anEvent printString , ': '
				, anException description printString.
	context := thisContext clone.
	basename := self class basename.
	self
		writeFuelContext: context
		named:
			anException class printString , '-' , anEvent class printString
				, '.txt'
		withBasename: basename.
	self writeEvent: anEvent printString withBasename: basename.
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
EDACErrorHelper >> writeCommand: aCommand withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename)
		/ (aCommand class printString , '.txt').
	(WriteStream on: result)
		nextPutAll: aCommand printString;
		close.
	^ result
]

{ #category : #handling }
EDACErrorHelper >> writeEvent: aString withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename) / 'event.txt'.
	(WriteStream on: result)
		nextPutAll: aString;
		close.
	^ result
]

{ #category : #handling }
EDACErrorHelper >> writeFuelContext: aContext named: aString withBasename: aBasename [
	| parentFolder |
	parentFolder := self class errorFolderFor: aBasename.
	^ EDACFuelHelper new
		writeFuelContext: aContext
		named: 'session.fuel'
		inFolder: parentFolder
]

{ #category : #handling }
EDACErrorHelper >> writeMessage: aString withBasename: aBasename [
	| result |
	result := (self class errorFolderFor: aBasename) / 'message.txt'.
	(WriteStream on: result)
		nextPutAll: aString;
		close.
	^ result
]
