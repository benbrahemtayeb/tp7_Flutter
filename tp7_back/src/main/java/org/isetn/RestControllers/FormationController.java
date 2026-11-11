package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Formation;
import org.isetn.repository.FormationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/formations")
public class FormationController {

    @Autowired
    private FormationRepository formationRepository;

    @GetMapping
    public List<Formation> getAll() {
        return formationRepository.findAll();
    }

    @PostMapping
    public Formation add(@RequestBody Formation f) {
        return formationRepository.save(f);
    }

    @PutMapping("/{id}")
    public Formation update(@PathVariable Integer id, @RequestBody Formation f) {
        f.setId(id);
        return formationRepository.save(f);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Integer id) {
        formationRepository.deleteById(id);
    }
}
