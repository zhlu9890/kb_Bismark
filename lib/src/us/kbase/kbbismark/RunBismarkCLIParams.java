
package us.kbase.kbbismark;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: RunBismarkCLIParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "command_name",
    "options"
})
public class RunBismarkCLIParams {

    @JsonProperty("command_name")
    private java.lang.String commandName;
    @JsonProperty("options")
    private List<String> options;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("command_name")
    public java.lang.String getCommandName() {
        return commandName;
    }

    @JsonProperty("command_name")
    public void setCommandName(java.lang.String commandName) {
        this.commandName = commandName;
    }

    public RunBismarkCLIParams withCommandName(java.lang.String commandName) {
        this.commandName = commandName;
        return this;
    }

    @JsonProperty("options")
    public List<String> getOptions() {
        return options;
    }

    @JsonProperty("options")
    public void setOptions(List<String> options) {
        this.options = options;
    }

    public RunBismarkCLIParams withOptions(List<String> options) {
        this.options = options;
        return this;
    }

    @JsonAnyGetter
    public Map<java.lang.String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(java.lang.String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public java.lang.String toString() {
        return ((((((("RunBismarkCLIParams"+" [commandName=")+ commandName)+", options=")+ options)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
