
package us.kbase.kbbismark;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: bismarkResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "alignment_ref"
})
public class BismarkResult {

    @JsonProperty("alignment_ref")
    private String alignmentRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("alignment_ref")
    public String getAlignmentRef() {
        return alignmentRef;
    }

    @JsonProperty("alignment_ref")
    public void setAlignmentRef(String alignmentRef) {
        this.alignmentRef = alignmentRef;
    }

    public BismarkResult withAlignmentRef(String alignmentRef) {
        this.alignmentRef = alignmentRef;
        return this;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        return ((((("BismarkResult"+" [alignmentRef=")+ alignmentRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
