import Foundation

@main
public struct rf_exposure_swift {

    public static func main() {
        let xmtr_power: Int = 1000
        let feedline_length: Int = 73
        let duty_cycle: Float32 = 0.5
        let per_30: Float32 = 0.5
        
        let c1 = CableValues(k1: 0.122290, k2: 0.000260)
        
        let all_frequency_values: [FrequencyValues] = [
            FrequencyValues(freq: 7.3, swr: 2.25, gaindbi: 1.5),
            FrequencyValues(freq: 14.35, swr: 1.35, gaindbi: 1.5),
            FrequencyValues(freq: 18.1, swr: 3.7, gaindbi: 1.5),
            FrequencyValues(freq: 21.45, swr: 4.45, gaindbi: 1.5),
            FrequencyValues(freq: 24.99, swr: 4.1, gaindbi: 1.5),
            FrequencyValues(freq: 29.7, swr: 2.18, gaindbi: 4.5)]
        
        all_frequency_values.forEach{
            let yarg = calculate_uncontrolled_safe_distance(freq_values: $0, cable_values: c1, transmitter_power: xmtr_power, feedline_length: feedline_length, duty_cycle: duty_cycle, uncontrolled_percentage_30_minutes: per_30)
            let yargstring = String(format: "%.2f", yarg)
            print(yargstring)
        }
    }
}

struct CableValues {
    
    var k1 : Float32
    var k2 : Float32
}

struct FrequencyValues {
    
    var freq: Float32
    var swr: Float32
    var gaindbi: Float32
}

func calculate_reflection_coefficient(freq_values: FrequencyValues) -> Float32 {
    return abs((freq_values.swr - 1)/(freq_values.swr + 1))
}

func calculate_feedline_loss_for_matched_load_at_frequency(feedline_length: Int, feedline_loss_per_100ft_at_frequency: Float32) -> Float32 {
    return (Float32(feedline_length)/100.0) * feedline_loss_per_100ft_at_frequency
}

func calculate_feedline_loss_for_matched_load_at_frequency_percentage(feedline_loss_for_matched_load: Float32) -> Float32 {
    return pow(10, -feedline_loss_for_matched_load/10.0)
}

func calculate_feedline_loss_per_100ft_at_frequency(freq_values: FrequencyValues, cable_values: CableValues ) -> Float32 {
    return cable_values.k1 * sqrt(freq_values.freq + cable_values.k2 * freq_values.freq)
}

func calculate_feedline_loss_for_swr(feedline_loss_for_matched_load_percentage: Float32, gamma_squared: Float32) -> Float32 {
    return -10 * log10(feedline_loss_for_matched_load_percentage * ((1 - gamma_squared)/(1 - pow(feedline_loss_for_matched_load_percentage,2) * gamma_squared)))
}

func calculate_feedline_loss_for_swr_percentage(feedline_loss_for_swr: Float32) -> Float32 {
    return (100 - 100/pow(10,(feedline_loss_for_swr/10)))/100
}

func calculate_uncontrolled_safe_distance(freq_values: FrequencyValues, cable_values:CableValues, transmitter_power: Int, feedline_length: Int, duty_cycle: Float32, uncontrolled_percentage_30_minutes: Float32) -> Float32 {
    
    let gamma = calculate_reflection_coefficient(freq_values: freq_values)
    
    let feedline_loss_per_100ft_at_frequency = calculate_feedline_loss_per_100ft_at_frequency(freq_values: freq_values, cable_values: cable_values)
    
    let feedline_loss_for_matched_load_at_frequency = calculate_feedline_loss_for_matched_load_at_frequency(feedline_length: feedline_length, feedline_loss_per_100ft_at_frequency: feedline_loss_per_100ft_at_frequency)
    
    let feedline_loss_for_matched_load_at_frequency_percentage =
        calculate_feedline_loss_for_matched_load_at_frequency_percentage(feedline_loss_for_matched_load: feedline_loss_for_matched_load_at_frequency)
    
    let gamma_squared = pow(abs(gamma), 2)
    
    let feedline_loss_for_swr = calculate_feedline_loss_for_swr(feedline_loss_for_matched_load_percentage: feedline_loss_for_matched_load_at_frequency_percentage, gamma_squared: gamma_squared)
    
    let feedline_loss_for_swr_percentage = calculate_feedline_loss_for_swr_percentage(feedline_loss_for_swr: feedline_loss_for_swr)
    
    let power_loss_at_swr = feedline_loss_for_swr_percentage * Float32(transmitter_power)
    
    let peak_envelope_power_at_antenna = Float32(transmitter_power) - power_loss_at_swr
    
    let uncontrolled_average_pep = peak_envelope_power_at_antenna * duty_cycle * uncontrolled_percentage_30_minutes
    
    let mpe_s = 180/pow(freq_values.freq, 2)
    
    let gain_decimal = pow(10, freq_values.gaindbi/10)
    
    return sqrt((0.219 * uncontrolled_average_pep * gain_decimal)/mpe_s)
    
}



