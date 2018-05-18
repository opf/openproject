import {input} from 'reactivestates';
import {SwitchState} from "./switch-state";

describe("SwitchState", function () {

  it("switching", function () {
    const automata = new SwitchState<"Init" | "Phase1">();

    // switch and value to process differently based on the switch
    const value = input("result");

    // Output states of value when matching substate is active
    const whenInit = automata.fireOnTransition(value, 'Init');
    const whenPhase1 = automata.fireOnTransition(value, 'Phase1');

    // Initialized with <no value>, so neither stream is active
    expect(whenInit.hasValue()).to.be.false;
    expect(whenPhase1.hasValue()).to.be.false;

    // Test: switch to valid substate
    automata.transition("Init");

    // Invalid substate will yield TS error
    // automata.switch("Unknown"); will result in TS error

    expect(whenInit.hasValue()).to.be.true;
    expect(whenPhase1.hasValue()).to.be.false;

    // Test: switch to Phase1
    automata.transition("Phase1");
    expect(whenInit.hasValue()).to.be.false;
    expect(whenPhase1.hasValue()).to.be.true;

    // Reset substate
    automata.reset();
    expect(whenInit.hasValue()).to.be.false;
    expect(whenPhase1.hasValue()).to.be.false;

  });

});
