var CommandLineUtility = function (config) {
	
	this.userProvidedArguments = process.argv.slice(2);
	this.help = config.help || "No help.";

	
	this.processUserProvidedArguments(config);
	
	config.processArguments.call(this);
	
};

CommandLineUtility.prototype = {
	
	systemOut: function (message) {
		
		console.log("\n    " + message + "\n");
		
	},
	
	processUserProvidedArguments: function (config) {
		
		this.requiredArguments = {};
		this.optionalArguments = {};
		
		for ( var i = 0, len = config.requiredArguments.length; i < len; i += 1 ) {
		
			var argument = config.requiredArguments[i],
				argumentIndex = this.userProvidedArguments.indexOf("-" + argument);
			
			if ( argumentIndex > -1 ) {
				
				var value = this.userProvidedArguments[argumentIndex + 1];
				
				if ( value && value.indexOf("-") == -1 ) {
					
					this.requiredArguments[argument] = this.userProvidedArguments[argumentIndex + 1];					
					
				}
				else {

					this.systemOut(this.help);
					process.exit(1);

				}
				
			}
			else {
				
				this.systemOut(this.help);
				process.exit(1);
				
			}
		
		}
	
		for ( var i = 0, len = config.optionalArguments.length; i < len; i += 1 ) {
		
			var argument = config.optionalArguments[i],
				argumentIndex = this.userProvidedArguments.indexOf("-" + argument);
		
			if (argumentIndex > -1) {
				
				var value = this.userProvidedArguments[argumentIndex + 1];
				
				if ( value && (value.indexOf("-") == -1 || (value.indexOf("-") > 2)) ) {
					
					this.optionalArguments[argument] = this.userProvidedArguments[argumentIndex + 1];					
					
				}
				else {
					
					this.systemOut(argument);
					this.systemOut(this.help);
					process.exit(1);

				}
				
			}
			else if ( config.defaults && config.defaults[argument] ) {

				this.optionalArguments[argument] = config.defaults[argument];

			}
		
		}
	
	}
	
};

module.exports = CommandLineUtility;